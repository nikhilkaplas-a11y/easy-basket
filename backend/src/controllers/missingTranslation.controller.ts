import { Request, Response } from "express";
import { AppDataSource } from "../config/database";
import { MissingTranslation } from "../entities/MissingTranslation";
import { Translation } from "../entities/Translation";
import { TranslationService } from "../services/translation.service";

export class MissingTranslationController {

    /**
     * Get pending missing translations
     *
     * GET /api/admin/missing-translations
     */
    static async getMissingTranslations(
        _req: Request,
        res: Response
    ) {

        try {

            const repository =
                AppDataSource.getRepository(MissingTranslation);

            const missingTranslations =
                await repository.find({
                    where: {
                        status: "pending",
                    },
                    order: {
                        createdAt: "ASC",
                    },
                });

            return res.json({
                success: true,
                count: missingTranslations.length,
                data: missingTranslations,
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
     */
    static async completeMissingTranslation(
        req: Request,
        res: Response
    ) {

        try {

            const id = Number(req.params.id);

            if (!Number.isInteger(id)) {

                return res.status(400).json({
                    success: false,
                    message: "Invalid translation id",
                });
            }

            const {
                hi,
                pa,
            } = req.body;

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
             * At least one language should be provided.
             */
            if (
                (hi === undefined || hi === null || hi === "") &&
                (pa === undefined || pa === null || pa === "")
            ) {

                return res.status(400).json({
                    success: false,
                    message: "Provide Hindi or Punjabi translation",
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

            if (translation) {

                /*
                 * Update existing translation.
                 */
                if (hi !== undefined)
                    translation.hi = hi;

                if (pa !== undefined)
                    translation.pa = pa;

                translation.en = missing.en;
                translation.type = missing.type;

                await translationRepository.save(
                    translation
                );

            } else {

                /*
                 * Create a new translation.
                 */
                translation =
                    translationRepository.create({
                        key: missing.key,
                        en: missing.en,
                        hi: hi || "",
                        pa: pa || "",
                        type: missing.type,
                    });

                await translationRepository.save(
                    translation
                );
            }

            /*
             * Mark missing entry as completed.
             */
            missing.status = "completed";

            await missingRepository.save(
                missing
            );

            /*
             * Update in-memory translation cache immediately.
             *
             * No server restart required.
             */
            TranslationService.addToCache(
                translation
            );

            return res.json({
                success: true,
                message: "Translation completed successfully",
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