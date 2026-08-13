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

export class ResponseTranslator {

    static translate(
        data: any,
        language: SupportedLanguage
    ): any {

        if (data == null)
            return data;

        /*
         * Array
         */
        if (Array.isArray(data)) {

            return data.map(item =>
                this.translate(item, language)
            );
        }

        /*
         * Object
         */
        if (typeof data === "object") {

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
                            language
                        );

                } else if (
                    value !== null &&
                    typeof value === "object"
                ) {

                    /*
                     * Recursively process nested objects
                     * and arrays.
                     */
                    translated[key] =
                        this.translate(
                            value,
                            language
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