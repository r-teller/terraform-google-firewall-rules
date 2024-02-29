# Required tools for setup
pwd=$(pwd)
pushd "${pwd}/../schemas/"

# npm install -g json-dereference-cli
json-dereference -s ./JSONSchema.json  -o ./resolved/resolved.schema.json

# apt-get install moreutils
jq "." resolved/resolved.schema.json | sponge resolved/resolved.schema.json
cp ./resolved/resolved.schema.json "${pwd}/src/Schema/resolved.schema.json"
popd

rm -rf ./public/documentation/*
# pip install json-schema-for-humans
generate-schema-doc --config expand_buttons=true ./src/Schema/resolved.schema.json ./public/documentation/index.html

# apt-get install npm
# npm install #// run externally for now :(
# npm run build #// run externally for now :(
# rm -rf ../docs/*
# mv ./build/* ../docs
# rm -r ./build