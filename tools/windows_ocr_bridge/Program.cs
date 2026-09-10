using System;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Threading.Tasks;
using Windows.Globalization;
using Windows.Graphics.Imaging;
using Windows.Media.Ocr;
using Windows.Storage.Streams;

var imagePath = args.FirstOrDefault();
if (string.IsNullOrWhiteSpace(imagePath))
{
    Console.Error.WriteLine("Usage: WindowsOcrBridge <image-path>");
    Environment.Exit(1);
}

try
{
    if (!File.Exists(imagePath))
    {
        throw new FileNotFoundException($"Image file not found: {imagePath}");
    }

    using var inputStream = File.OpenRead(imagePath);
    using var memoryStream = new MemoryStream();
    inputStream.CopyTo(memoryStream);
    memoryStream.Position = 0;

    var randomAccessStream = memoryStream.AsRandomAccessStream();
    var decoder = await BitmapDecoder.CreateAsync(randomAccessStream);
    var bitmap = await decoder.GetSoftwareBitmapAsync();

    if (bitmap.BitmapPixelFormat != BitmapPixelFormat.Bgra8 ||
        bitmap.BitmapAlphaMode != BitmapAlphaMode.Premultiplied)
    {
        bitmap = SoftwareBitmap.Convert(bitmap, BitmapPixelFormat.Bgra8, BitmapAlphaMode.Premultiplied);
    }

    var language = new Language("en-US");
    var engine = OcrEngine.TryCreateFromLanguage(language);
    if (engine is null)
    {
        engine = OcrEngine.TryCreateFromUserProfileLanguages();
    }

    if (engine is null)
    {
        throw new InvalidOperationException("OCR engine is not available on this Windows installation.");
    }

    var result = await engine.RecognizeAsync(bitmap);
    var text = string.Join(
        Environment.NewLine,
        result.Lines.Select(line => line.Text.Trim()).Where(line => !string.IsNullOrWhiteSpace(line)));

    Console.WriteLine("OCR_TEXT_BEGIN");
    Console.WriteLine(text.Trim());
    Console.WriteLine("OCR_TEXT_END");
}
catch (Exception ex)
{
    Console.Error.WriteLine(ex.ToString());
    Environment.Exit(2);
}
