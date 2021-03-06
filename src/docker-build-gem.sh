
#!/bin/bash

DIR="$(pwd)"

BUILD_DIR=.build
GEM_FOLDER="$DIR/octo-fffc"

GEM_MAJOR_VERSION=${GEM_MAJOR_VERSION:-'0.1.0'}
GEM_VERSION='0.1.0'

GEM_VERSION_FILE="$DIR/octo-fffc/lib/octo/fffc/version.rb"

if [ "$1" == "--install" ] ; then 
    INSTALL_GEM=1
fi

function validate_exit_code()
{
    CODE=$1
    MGS=$2
 
    [ $CODE -eq 0 ] && echo "   [+] exit code is 0, continue..."
    [ $CODE -ne 0 ] && echo "   [-] exiting with non-zero code [$CODE] - $MGS" && exit $CODE
}

function patch_gemfile() {
    
    echo "Patching file  : $GEM_VERSION_FILE"
    echo "  Replacing VERSION to VERSION ${GEM_VERSION}"
    
    sed -i "/VERSION/c\ VERSION=\"${GEM_VERSION}\"" "$GEM_VERSION_FILE"
    validate_exit_code $? "Cannot update gemfile: $GEM_VERSION_FILE"
}

function cat_gemfile() {
    echo "Showing file: $GEM_VERSION_FILE"
    cat $GEM_VERSION_FILE
}

function cleanup_old_gems() {
    echo 'Cleanin up previous gems..'
    rm -rf ./octo-fffc/*.gem
}

function build_gem() {

    echo "Building gem..."
    sh -c "cd $GEM_FOLDER && gem build *.gemspec"

    validate_exit_code $? "Cannot build gem in folder: $GEM_FOLDER"
}

function prepare_build_folder() {
    echo "Creating build dir: $BUILD_DIR"
    mkdir -p $BUILD_DIR
    validate_exit_code $? "Cannot create folder: $BUILD_DIR"

    echo "Cleaning up build dir: $BUILD_DIR"
    rm -rf $BUILD_DIR/*
    validate_exit_code $? "Cannot cleanup folder: $BUILD_DIR"
}

function get_latest_gem() {
    if [[ -z $APPVEYOR_REPO_BRANCH ]] ; then 
        LATEST_GEM_VERSION="latest"
    else 
        LATEST_GEM_VERSION="${APPVEYOR_REPO_BRANCH}-latest"
    fi

    echo "$BUILD_DIR/octo-fffc-${LATEST_GEM_VERSION}.gem"
}

function copy_gem_to_build_folder() {
    echo "Copying newly built gem to build dir: $BUILD_DIR"
    cp ./octo-fffc/*.gem $BUILD_DIR/
    validate_exit_code $? "Cannot copy latest gem to folder: $BUILD_DIR"

    LATEST_GEM_PATH=$(get_latest_gem)

    cp ./octo-fffc/octo-fffc-0*.gem $LATEST_GEM_PATH
    validate_exit_code $? "Cannot copy latest gem to folder: $BUILD_DIR"
}

echo "Bulding gem version: $GEM_VERSION"

if [[ -z $APPVEYOR_BUILD_NUMBER ]] ; then 
    echo 'Running locally, no patching for gem file'  
else
    patch_gemfile
fi

cat_gemfile

cleanup_old_gems
build_gem

prepare_build_folder
copy_gem_to_build_folder

echo "Completed build!"

if [ $INSTALL_GEM ] ; then 
    GEM_PATH=$(get_latest_gem)

    echo "Unisntalling gems"
    gem uninstall octo-fffc --force -x

    echo "Installing latest gem: $GEM_PATH"
    gem install --local $GEM_PATH --no-ri --no-rdoc --force
    
    validate_exit_code $? "Cannot install nighly gem: $BUILD_DIR"

    echo "Completed install!"
fi

exit 0