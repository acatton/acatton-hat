var gulp = require('gulp'),
    bower = require('gulp-bower'),
    concat = require('gulp-concat'),
    elm = require('gulp-elm'),
    inline = require('gulp-inline'),
    less = require('gulp-less'),
    minify_css = require('gulp-minify-css'),
    minify_html = require('gulp-minify-html'),
    uglifyjs = require('gulp-uglifyjs');

gulp.task('elm-init', elm.init);

gulp.task('elm', ['elm-init'], function () {
  return gulp.src('src/*.elm')
             .pipe(elm())
             .pipe(gulp.dest('build/js/'));
});

gulp.task('js', ['elm'], function () {
  return gulp.src(['build/js/Hat.js', 'src/loader.js'])
             .pipe(concat('script.js'))
             .pipe(gulp.dest('build/public/'));
});

gulp.task('lesscss', function () {
  return gulp.src(['src/*.less'])
             .pipe(less())
             .pipe(gulp.dest('build/css/'));
});

gulp.task('bower', function () {
  return bower().pipe(gulp.dest('build/vendors'));
});

gulp.task('css', ['lesscss', 'bower'], function () {
  return gulp.src(['build/vendors/normalize.css/normalize.css',
                   'build/css/style.css'])
             .pipe(concat('style.css'))
             .pipe(gulp.dest('build/public/'));
});


gulp.task('html', ['js', 'css'], function () {
  return gulp.src('src/index.html')
             .pipe(inline({
                base: 'build/public/',
                js: uglifyjs(),
                css: minify_css({keepSpecialComments: 0}),
              }))
             .pipe(minify_html())
             .pipe(gulp.dest('build/'));
});

gulp.task('default', ['html'], function () { });
