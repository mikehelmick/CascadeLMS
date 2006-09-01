#!/bin/sh
rsync -avz -e ssh helmicmt@work.mikehelmick.com:/srv/www/rails/cscourseware/shared/storage/* /srv/www/rails/cscourseware/shared/storage/

