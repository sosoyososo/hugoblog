git add .;
git commit -m 'add post';
git push origin master;
curl -L http://webhook.karsa.info/hooks/hugo-blog-update\?token\=$blogupdatetoken
