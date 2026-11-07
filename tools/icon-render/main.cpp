// SPDX-License-Identifier: MIT
// Renders the master SVG app icon into every platform format.
//
//   iptvx_icongen <icon.svg> <out-dir>
//
// Produces in <out-dir>:
//   iptvx.iconset/   macOS iconset (convert with `iconutil -c icns`)
//   iptvx.ico        Windows icon (16–256 px; BMP ≤ 48 px, PNG above)
//   iptvx-<n>.png    Linux hicolor sizes (16–512)

#include <QBuffer>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QSvgRenderer>
#include <QtEndian>

#include <cstdio>

using namespace Qt::StringLiterals;

namespace {

QImage render(QSvgRenderer &svg, int size)
{
    QImage image(size, size, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);
    QPainter painter(&image);
    painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
    svg.render(&painter, QRectF(0, 0, size, size));
    return image;
}

QByteArray png(const QImage &image)
{
    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "PNG");
    return bytes;
}

// Classic DIB payload (BITMAPINFOHEADER + bottom-up BGRA + AND mask), which
// Microsoft recommends for icon entries up to 48 px; larger entries use PNG.
QByteArray dib(const QImage &source)
{
    const QImage image = source.convertToFormat(QImage::Format_ARGB32); // straight alpha
    const int w = image.width();
    const int h = image.height();
    QByteArray out;
    auto put16 = [&out](quint16 v) { v = qToLittleEndian(v); out.append(reinterpret_cast<const char *>(&v), 2); };
    auto put32 = [&out](quint32 v) { v = qToLittleEndian(v); out.append(reinterpret_cast<const char *>(&v), 4); };

    const int maskStride = ((w + 31) / 32) * 4;
    put32(40);                     // header size
    put32(quint32(w));
    put32(quint32(h * 2));         // XOR + AND masks
    put16(1);                      // planes
    put16(32);                     // bpp
    put32(0);                      // BI_RGB
    put32(quint32(w * h * 4 + maskStride * h));
    put32(0); put32(0); put32(0); put32(0);

    for (int y = h - 1; y >= 0; --y) {
        const auto *line = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = 0; x < w; ++x) {
            const QRgb px = line[x];
            out.append(char(qBlue(px))).append(char(qGreen(px))).append(char(qRed(px))).append(char(qAlpha(px)));
        }
    }
    // AND mask: 1 = transparent. Alpha already encodes it; keep it consistent.
    for (int y = h - 1; y >= 0; --y) {
        QByteArray row(maskStride, 0);
        const auto *line = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = 0; x < w; ++x)
            if (qAlpha(line[x]) == 0)
                row[x / 8] = char(row[x / 8] | (0x80 >> (x % 8)));
        out.append(row);
    }
    return out;
}

// Windows icon: every size the shell uses at 100–200 % scaling.
bool writeIco(const QString &path, QSvgRenderer &svg)
{
    const int sizes[] = { 16, 20, 24, 32, 40, 48, 64, 96, 128, 256 };
    const int count = int(std::size(sizes));
    QList<QByteArray> payloads;
    for (int s : sizes)
        payloads.append(s <= 48 ? dib(render(svg, s)) : png(render(svg, s)));

    QByteArray out;
    auto put16 = [&out](quint16 v) { v = qToLittleEndian(v); out.append(reinterpret_cast<const char *>(&v), 2); };
    auto put32 = [&out](quint32 v) { v = qToLittleEndian(v); out.append(reinterpret_cast<const char *>(&v), 4); };

    put16(0);     // reserved
    put16(1);     // type: icon
    put16(quint16(count));
    quint32 offset = 6 + 16 * quint32(count);
    for (int i = 0; i < count; ++i) {
        const int s = sizes[i];
        out.append(char(s >= 256 ? 0 : s)); // width (0 = 256)
        out.append(char(s >= 256 ? 0 : s)); // height
        out.append(char(0));                // palette
        out.append(char(0));                // reserved
        put16(1);                           // colour planes
        put16(32);                          // bits per pixel
        put32(quint32(payloads[i].size()));
        put32(offset);
        offset += quint32(payloads[i].size());
    }
    for (const QByteArray &p : payloads)
        out.append(p);

    QFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(out) == out.size();
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    const QStringList args = QCoreApplication::arguments();
    if (args.size() != 3) {
        std::fprintf(stderr, "usage: iptvx_icongen <icon.svg> <out-dir>\n");
        return 2;
    }
    QSvgRenderer svg(args.at(1));
    if (!svg.isValid()) {
        std::fprintf(stderr, "invalid SVG: %s\n", qPrintable(args.at(1)));
        return 1;
    }
    const QDir out(args.at(2));
    QDir().mkpath(out.filePath(u"iptvx.iconset"_s));

    // macOS iconset: 16, 32, 128, 256, 512 at 1x and 2x.
    for (int base : { 16, 32, 128, 256, 512 }) {
        render(svg, base).save(out.filePath(u"iptvx.iconset/icon_%1x%1.png"_s.arg(base)));
        render(svg, base * 2).save(out.filePath(u"iptvx.iconset/icon_%1x%1@2x.png"_s.arg(base)));
    }
    // freedesktop hicolor sizes (Linux) — also used as the window icon.
    for (int size : { 16, 24, 32, 48, 64, 128, 256, 512 })
        render(svg, size).save(out.filePath(u"iptvx-%1.png"_s.arg(size)));

    if (!writeIco(out.filePath(u"iptvx.ico"_s), svg)) {
        std::fprintf(stderr, "failed to write iptvx.ico\n");
        return 1;
    }
    std::printf("icons written to %s\n", qPrintable(out.absolutePath()));
    return 0;
}
