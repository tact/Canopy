doc-preview:
  SPI_BUILDER=1 swift package \
    generate-documentation \
    --target Canopy \
    --disable-indexing \
    --transform-for-static-hosting
  
  # First open will fail because the web server hasn’t yet started.
  # Just hit Refresh in browser to actually load the page.
  open "http://localhost:8000/documentation/Canopy/"
  python3 -m http.server 8000 -d .build/plugins/Swift-DocC/outputs/Canopy.doccarchive

testtools-doc-preview:
  SPI_BUILDER=1 swift package \
    generate-documentation \
    --target CanopyTestTools \
    --disable-indexing \
    --transform-for-static-hosting
  
  open "http://localhost:8000/documentation/CanopyTestTools/"
  python3 -m http.server 8000 -d .build/plugins/Swift-DocC/outputs/CanopyTestTools.doccarchive
