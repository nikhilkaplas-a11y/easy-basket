import multer from 'multer';
import { Request } from 'express';

/**
 * A rejection the CLIENT should see verbatim.
 *
 * multer reports a filter rejection by handing an Error to its callback, which
 * Express routes to the terminal error handler — and that handler deliberately
 * answers a generic 500 rather than leaking internal messages. Correct in
 * general, wrong here: "only JPG, PNG and WebP are allowed" is exactly what the
 * user needs to read.
 *
 * `expose` marks the ones that are safe to show, mirroring the convention the
 * http-errors package uses. See the error handler in index.ts.
 */
function clientError(message: string, status = 400): Error {
  const err = new Error(message) as Error & { status?: number; expose?: boolean };
  err.status = status;
  err.expose = true;
  return err;
}

/**
 * Multer configuration for file uploads
 * Stores files in memory (as buffers) for S3 upload
 */
const storage = multer.memoryStorage();

/**
 * File filter - only allow image files
 */
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(clientError('Invalid file type. Only JPG, PNG, and WebP images are allowed.'));
  }
};

/**
 * Multer upload middleware
 * - Max file size: 5MB
 * - Single file upload
 * - Memory storage (for S3 upload)
 */
export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
});

/**
 * Single file upload middleware
 */
export const uploadSingle = upload.single('file');

/**
 * Separate uploader for the bulk-inventory spreadsheet.
 *
 * `uploadSingle` above cannot be reused: its filter allows image MIME types
 * only, so it rejects a CSV outright.
 *
 * The MIME type is only a first-pass hint here — browsers are wildly
 * inconsistent about what they send for a .csv (Excel-authored files often
 * arrive as application/vnd.ms-excel, sometimes as application/octet-stream),
 * so the extension is accepted as an alternative. The real validation is the
 * header check in InventorySheetService.plan, which rejects anything that is
 * not an inventory sheet regardless of what it claims to be. Unlike an image
 * upload there is no risk in being permissive at this stage: the file is parsed
 * as text and never stored or served back.
 *
 * 10MB against the image path's 5MB — a 10,000-row sheet is a couple of MB, and
 * the ceiling exists to stop something absurd rather than to be tight.
 */
const csvFileFilter = (
  _req: Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
) => {
  const okMime = [
    'text/csv',
    'text/plain',
    'application/csv',
    'application/vnd.ms-excel',
    'application/octet-stream',
  ].includes(file.mimetype);
  const okExtension = /\.csv$/i.test(file.originalname ?? '');

  if (okMime || okExtension) {
    cb(null, true);
  } else {
    cb(clientError('Please upload the .csv file you downloaded and edited.'));
  }
};

export const uploadCsvSingle = multer({
  storage,
  fileFilter: csvFileFilter,
  limits: { fileSize: 10 * 1024 * 1024 },
}).single('file');
