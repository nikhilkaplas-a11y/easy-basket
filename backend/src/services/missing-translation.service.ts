import { AppDataSource } from "../config/database";
import { MissingTranslation } from "../entities/MissingTranslation";


export class MissingTranslationService {

    static async record(
        key: string,
        type: string = "product"
    ): Promise<void> {

        if (!key)
            return;

        const value = key.trim();

        if (!value)
            return;

        const normalizedKey = value.toLowerCase();

        try {
            const repository =
                AppDataSource.getRepository(MissingTranslation);

            const existing =
                await repository.findOne({
                    where: {
                        key: normalizedKey,
                    },
                });

            if (existing)
                return;

            await repository.save({
                key: normalizedKey,
                en: value,
                type,
                status: "pending",
            });

            console.log(
                `🌐 Missing translation recorded: ${value}`
            );

        } catch (error: any) {
            console.error(
                `⚠️ Could not record missing translation: ${value}`,
                error?.message || error
            );
        }
    }
}