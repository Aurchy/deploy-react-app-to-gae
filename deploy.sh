# will create this two dirs from scratch later
rm -rf build deployables

npm run build
gzip build/static/css/* build/static/js/* build/static/images/*
for old in build/static/css/*.gz build/static/js/*.gz build/static/images/*.gz; do mv $old ${old%???}; done

# create folder deployables from scratch and move all deployable items to it
mkdir deployables
cp app.yaml deployables/
# copy package.json for your node application, not the one for your react app
cp deploy/package.json deployables/
cp -r build deployables/
# node server
cp index.js deployables/

# rsync static objects hosted on cloud storage
gsutil -m rsync -r ./deployables/build/static/css gs://my-staging-bucket/build/static/css
gsutil -m rsync -r ./deployables/build/static/images gs://my-staging-bucket/build/static/images
gsutil -m rsync -r ./deployables/build/static/js gs://my-staging-bucket/build/static/js

# set metadata for static objects hosted on cloud storage
gsutil -m setmeta -h "Content-Encoding: gzip" gs://my-staging-bucket/build/static/css/* \
                     gs://my-staging-bucket/build/static/js/* \
                     gs://my-staging-bucket/build/static/images/*
gsutil -m setmeta -h "Cache-Control: public, max-age=31536000" gs://my-staging-bucket/build/static/css/* \
                  gs://my-staging-bucket/build/static/js/* \
                  gs://my-staging-bucket/build/static/images/*

gcloud app deploy deployables/app.yaml -q --version="fe-staging" --no-promote
