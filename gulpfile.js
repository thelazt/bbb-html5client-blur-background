var gulp = require('gulp');
var npmDist = require('gulp-npm-dist');
var rename = require('gulp-rename');

gulp.task('copy:dist', function() {
    return gulp.src(npmDist(), {base:'./node_modules/'})
        .pipe(rename(function(path) {
            path.dirname = path.dirname.replace(/\/dist/, '').replace(/\\dist/, '');
        }))
        .pipe(gulp.dest('./dist/'));
});
