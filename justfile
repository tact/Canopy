doc-preview:
  SPI_BUILDER=1 swift package --disable-sandbox preview-documentation \
  --enable-experimental-combined-documentation \
  --target Canopy --target CanopyTestTools

doc-build:
  SPI_BUILDER=1 swift package \
    generate-documentation \
    --enable-experimental-combined-documentation \
    --target Canopy --target CanopyTestTools \
    --disable-indexing \
    --transform-for-static-hosting
  
  # How to locally serve it as a test.
  # python3 -m http.server 8000 -d .build/plugins/Swift-DocC/outputs/Canopy.doccarchive
  # To test in local browser, open this URL:
  # http://localhost:8000/documentation/Canopy/

doc-deploy: (doc-build)
  rsync -azhv --delete .build/plugins/Swift-DocC/outputs/Canopy.doccarchive/ canopy-docs.justtact.com:/var/www/canopy-docs
