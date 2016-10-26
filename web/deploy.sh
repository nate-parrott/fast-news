cp -R app/ ../fast-news/app
cp -R app-static/ ../fast-news/app-static
cp index.html ../fast-news/app/index.html
cd ../fast-news
appcfg.py update app-default.yaml
cd ../web
