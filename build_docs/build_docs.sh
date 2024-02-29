# Required tools for setup
pwd=$(pwd)
pushd "${pwd}/../schemas/"
json-dereference -s ./JSONSchema.json  -o ./resolved/resolved.schema.json
jq "." resolved/resolved.schema.json | sponge resolved/resolved.schema.json
cp ./resolved/resolved.schema.json "${pwd}/src/Schema/resolved.schema.json"
popd

rm -rf ./public/documentation/*
generate-schema-doc --config expand_buttons=true ./src/Schema/resolved.schema.json ./public/documentation/index.html

# npm install #// run externally for now :(
# npm run build #// run externally for now :(
# rm -rf ../docs/*
# mv ./build/* ../docs
# rm -r ./build