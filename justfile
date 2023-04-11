default-target := 'Canopy'

doc-preview target=default-target:
  SPI_BUILDER=1 swift package --disable-sandbox preview-documentation --target {{target}}

doc-build target=default-target:
  SPI_BUILDER=1 swift package \
    generate-documentation \
    --target {{target}} \
    --disable-indexing \
    --transform-for-static-hosting
  
  # How to locally serve it as a test.
  # python3 -m http.server 8000 -d .build/plugins/Swift-DocC/outputs/{{target}}.doccarchive
  # To test in local browser, open this URL:
  # http://localhost:8000/documentation/{{target}}/

doc-deploy: (doc-build)
  rsync -azhv --delete .build/plugins/Swift-DocC/outputs/Canopy.doccarchive/ canopy-docs.justtact.com:/var/www/canopy-docs
