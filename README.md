# BlobFont
A utility for working with [blob fonts](https://github.com/ScrimpyCat/CommonGameKit/blob/master/assets/font/arial.font)

Can be used to convert BMFont files to blob fonts.

Usage
-----

This library can be used as an API in an app, or as an escript.

For escript simply build it using:

```bash
MIX_ENV=prod mix escript.build
mix escript.install blob_font
```

Or download a build from the releases.

```bash
blob_font arial.bin > arial.font
```
