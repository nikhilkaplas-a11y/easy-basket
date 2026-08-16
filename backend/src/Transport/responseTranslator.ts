import {
    TranslationService,
    SupportedLanguage
} from "../services/translation.service";

const TRANSLATABLE_FIELDS = new Set([
    "name",
    "description",
    "title",
    "subtitle",
]);

/*
 * Maps a response key onto the content type it holds, so a missing
 * translation is recorded as "category" instead of everything
 * defaulting to "product".
 */
const TYPE_HINTS: Record<string, string> = {
    product: "product",
    products: "product",
    category: "category",
    categories: "category",
    subcategory: "category",
    subcategories: "category",
    campaign: "campaign",
    campaigns: "campaign",
    banner: "banner",
    banners: "banner",
};

const DEFAULT_TYPE = "content";

export class ResponseTranslator {

    /**
     * Values that are objects but are NOT containers we should walk into.
     *
     * A Date has no enumerable own keys, so rebuilding it produces {}
     * and destroys the timestamp before res.json() can serialise it.
     * Buffers, typed arrays, Maps and Sets degrade the same way.
     */
    private static isWalkable(value: any): boolean {

        if (value === null || typeof value !== "object")
            return false;

        if (value instanceof Date)
            return false;

        if (Buffer.isBuffer(value))
            return false;

        if (value instanceof RegExp)
            return false;

        if (value instanceof Map || value instanceof Set)
            return false;

        /*
         * Typed arrays / DataView.
         */
        if (ArrayBuffer.isView(value))
            return false;

        return true;
    }

    /**
     * Derive the content type for a value being walked.
     *
     * TypeORM entities carry their class name, which is the most
     * reliable signal. Plain objects fall back to the parent key.
     */
    private static resolveType(
        value: any,
        inheritedType: string
    ): string {

        const constructorName =
            value?.constructor?.name;

        if (
            constructorName &&
            constructorName !== "Object" &&
            constructorName !== "Array"
        ) {
            return constructorName.toLowerCase();
        }

        return inheritedType;
    }

    static translate(
        data: any,
        language: SupportedLanguage,
        type: string = DEFAULT_TYPE
    ): any {

        /*
         * English is the source language.
         *
         * Return the payload untouched so responses keep their
         * Date objects, Buffers and entity prototypes intact.
         */
        if (language === "en")
            return data;

        return this.walk(data, language, type);
    }

    private static walk(
        data: any,
        language: SupportedLanguage,
        type: string
    ): any {

        if (data == null)
            return data;

        /*
         * Array
         */
        if (Array.isArray(data)) {

            return data.map(item =>
                this.walk(item, language, type)
            );
        }

        /*
         * Anything object-like that we must not rebuild
         * (Date, Buffer, Map, ...) is passed straight through.
         */
        if (typeof data === "object" && !this.isWalkable(data))
            return data;

        /*
         * Object
         */
        if (typeof data === "object") {

            const currentType =
                this.resolveType(data, type);

            const translated: any = {};

            for (const key of Object.keys(data)) {

                const value = data[key];

                /*
                 * Only these fields are sent to the
                 * translation system.
                 */
                if (
                    TRANSLATABLE_FIELDS.has(key) &&
                    typeof value === "string"
                ) {

                    translated[key] =
                        TranslationService.translate(
                            value,
                            language,
                            currentType
                        );

                } else if (
                    value !== null &&
                    typeof value === "object"
                ) {

                    /*
                     * Recursively process nested objects
                     * and arrays, carrying down the content type
                     * implied by this key.
                     */
                    translated[key] =
                        this.walk(
                            value,
                            language,
                            TYPE_HINTS[key] ?? currentType
                        );

                } else {

                    /*
                     * IDs, prices, status, error messages,
                     * URLs, etc. remain untouched.
                     */
                    translated[key] = value;
                }
            }

            return translated;
        }

        /*
         * Primitive values remain unchanged.
         */
        return data;
    }
}
