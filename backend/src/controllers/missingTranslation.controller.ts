import { Request, Response } from "express";
import { AppDataSource } from "../config/database";
import { MissingTranslation } from "../entities/MissingTranslation";
import { Translation } from "../entities/Translation";
import { TranslationService } from "../services/translation.service";
import { MissingTranslationService } from "../services/missing-translation.service";

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;

/** Treat undefined / null / blank alike. */
function cleanValue(input: unknown): string | null {

    if (typeof input !== "string")
        return null;

    const trimmed = input.trim();

    return trimmed.length ? trimmed : null;
}

export class MissingTranslationController {

    /**
     * Get missing translations
     *
     * GET /api/admin/missing-translations
     *     ?status=pending|completed|all
     *     &page=1&limit=50
     */
    static async getMissingTranslations(
        req: Request,
        res: Response
    ) {

        try {

            const repository =
                AppDataSource.getRepository(MissingTranslation);

            const status =
                String(req.query.status || "pending").toLowerCase();

            const page =
                Math.max(1, Number(req.query.page) || 1);

            const limit =
                Math.min(
                    MAX_LIMIT,
                    Math.max(1, Number(req.query.limit) || DEFAULT_LIMIT)
                );

            const where =
                status === "all"
                    ? {}
                    : { status };

            const [rows, total] =
                await repository.findAndCount({
                    where,
                    order: {
                        createdAt: "ASC",
                    },
                    skip: (page - 1) * limit,
                    take: limit,
                });

            return res.json({
                success: true,
                count: rows.length,
                total,
                page,
                limit,
                data: rows,
            });

        } catch (error) {

            console.error(
                "Error fetching missing translations:",
                error
            );

            return res.status(500).json({
                success: false,
                message: "Error fetching missing translations",
            });
        }
    }

    /**
     * Add translation for a missing entry
     *
     * PUT /api/admin/missing-translations/:id
     *
     * Body:
     * {
     *   "hi": "ताज़ा दूध",
     *   "pa": "ਤਾਜ਼ਾ ਦੁੱਧ"
     * }
     *
     * The entry is only marked "completed" once BOTH languages are
     * present, so a half-filled row stays visible to the admin.
     */
    static async completeMissingTranslation(
        req: Request,
        res: Response
    ) {

        try {

            const id = Number(req.params.id);

            if (!Number.isInteger(id) || id <= 0) {

                return res.status(400).json({
                    success: false,
                    message: "Invalid translation id",
                });
            }

            const hi = cleanValue(req.body?.hi);
            const pa = cleanValue(req.body?.pa);

            /*
             * At least one language should be provided.
             */
            if (!hi && !pa) {

                return res.status(400).json({
                    success: false,
                    message: "Provide Hindi or Punjabi translation",
                });
            }

            const missingRepository =
                AppDataSource.getRepository(MissingTranslation);

            const translationRepository =
                AppDataSource.getRepository(Translation);

            const missing =
                await missingRepository.findOne({
                    where: {
                        id,
                    },
                });

            if (!missing) {

                return res.status(404).json({
                    success: false,
                    message: "Missing translation not found",
                });
            }

            /*
             * Check whether translation already exists.
             */
            let translation =
                await translationRepository.findOne({
                    where: {
                        key: missing.key,
                    },
                });

            if (!translation) {

                translation =
                    translationRepository.create({
                        key: missing.key,
                        en: missing.en,
                        hi: null,
                        pa: null,
                        type: missing.type,
                    });
            }

            /*
             * Only overwrite a language that was actually supplied, so a
             * second call adding Punjabi does not wipe existing Hindi.
             */
            if (hi)
                translation.hi = hi;

            if (pa)
                translation.pa = pa;

            translation.en = missing.en;
            translation.type = missing.type;

            await translationRepository.save(translation);

            /*
             * Complete only when both languages are filled in.
             */
            missing.status =
                translation.hi && translation.pa
                    ? "completed"
                    : "pending";

            await missingRepository.save(missing);

            /*
             * Update this process's cache immediately, then tell every
             * other process to reload. No server restart required.
             */
            TranslationService.addToCache(translation);

            MissingTranslationService.forget(missing.key);

            await TranslationService.bumpVersion();

            return res.json({
                success: true,
                message:
                    missing.status === "completed"
                        ? "Translation completed successfully"
                        : "Translation saved. Still awaiting the other language.",
                data: {
                    missingTranslation: missing,
                    translation,
                },
            });

        } catch (error) {

            console.error(
                "Error completing missing translation:",
                error
            );

            return res.status(500).json({
                success: false,
                message: "Error completing missing translation",
            });
        }
    }
}
