import { AppDataSource } from "../config/database";
import { Translation } from "../entities/Translation";
import { MissingTranslationService } from "./missing-translation.service";

export type SupportedLanguage = "en" | "hi" | "pa";

export class TranslationService {

    /**
     * Memory Cache
     *
     * key -> Translation Entity
     */
    private static cache = new Map<string, Translation>();

    /**
     * Load all translations from database
     */
    static async loadCache(): Promise<void> {

        const repository = AppDataSource.getRepository(Translation);

        const translations = await repository.find();

        this.cache.clear();

        for (const translation of translations) {

            this.cache.set(
                translation.key.toLowerCase(),
                translation
            );

        }

        console.log(
            `🌍 Translation Cache Loaded (${this.cache.size} entries)`
        );
    }

    /**
     * Reload cache
     */
    static async reloadCache(): Promise<void> {
        await this.loadCache();
    }

    /**
     * Add / Update one translation in cache
     */
    static addToCache(
        translation: Translation
    ): void {

        this.cache.set(
            translation.key.toLowerCase(),
            translation
        );
    }

    /**
     * Remove translation from cache
     */
    static removeFromCache(
        key: string
    ): void {

        this.cache.delete(
            key.toLowerCase()
        );
    }

    /**
     * Translate a single value
     */
    static translate(
        value: string,
        language: SupportedLanguage
    ): string {

        if (!value)
            return value;

        /*
         * English is the source language.
         * No translation lookup is required.
         */
        if (language === "en")
            return value;

        const translation =
            this.cache.get(
                value.toLowerCase()
            );

        /*
         * Translation does not exist.
         *
         * Record it in the missing_translations table
         * without blocking the API response.
         */
        if (!translation) {

            void MissingTranslationService.record(value);

            return value;
        }

        switch (language) {

            case "hi":
                return translation.hi || translation.en;

            case "pa":
                return translation.pa || translation.en;

            default:
                return translation.en;
        }
    }

    /**
     * Translate an object.
     */
    static translateObject<T extends Record<string, any>>(
        object: T,
        fields: string[],
        language: SupportedLanguage
    ): T {

        const translated = { ...object } as Record<string, any>;

        for (const field of fields) {

            if (
                translated[field] &&
                typeof translated[field] === "string"
            ) {

                translated[field] =
                    this.translate(
                        translated[field],
                        language
                    );
            }
        }

        return translated as T;
    }

    /**
     * Translate list of objects
     */
    static translateArray<T extends Record<string, any>>(
        data: T[],
        fields: string[],
        language: SupportedLanguage
    ): T[] {

        return data.map(item =>
            this.translateObject(
                item,
                fields,
                language
            )
        );
    }

    /**
     * Check whether translation exists
     */
    static hasTranslation(
        key: string
    ): boolean {

        return this.cache.has(
            key.toLowerCase()
        );
    }

    /**
     * Cache size
     */
    static cacheSize(): number {

        return this.cache.size;
    }
}