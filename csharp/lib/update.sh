#! /bin/bash

if [ ! command -v jq &> /dev/null ]
then
    echo "jq required"
    exit
fi

getLatestGitHubRelease() {
    curl "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

getLatestNugetRelease() {
    curl "https://www.nuget.org/packages/$1/" | grep 'og:title' | sed "s/.*$1 \([^\"]*\).*/\1/"
}

getReleaseDelta() {
    curl https://api.github.com/repos/$1/compare/$2...$3 | jq .files[].filename
}

UPSTREAM=$(getLatestGitHubRelease google/libphonenumber)
DEPLOYED=$(getLatestNugetRelease libphonenumber-csharp)

if [ "$DEPLOYED" = "${UPSTREAM:1}" ]
then
    echo "versions match"
    exit
fi

cd ~/GitHub/libphonenumber/
PREVIOUS=$(git describe --abbrev=0)

FILES=$(getReleaseDelta google/libphonenumber $PREVIOUS $UPSTREAM)

if echo $FILES | grep '\.java'
then
   echo "has java"
   exit
fi

if echo $FILES | grep 'proto'
then
   echo "has proto"
   exit
fi

git fetch origin
git reset --hard $UPSTREAM
rm -rf ../libphonenumber-csharp/resources/*
cp -r resources/* ../libphonenumber-csharp/resources
cd ../libphonenumber-csharp
cd csharp/lib
javac DumpLocale.java && java DumpLocale > ../PhoneNumbers/LocaleData.cs
git add .
git commit -m "$UPSTREAM"
