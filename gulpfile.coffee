# coffeelint: disable=max_line_length

gulp = require 'gulp'
$ = (require 'gulp-load-plugins')()
run = require 'run-sequence'

onError = (error) ->
  $.util.log error
  process.exit 1 # note: shouldn't exit on a live-reload/watch environment

(->
  # disable Jasmine's built-in ExitCodeReporter, which exits the build even when successful
  # (found this by looking at the source code of gulp-jasmine and jasmine)
  Jasmine = require 'gulp-jasmine/node_modules/jasmine'
  ExitCodeReporter = require 'gulp-jasmine/node_modules/jasmine/lib/reporters/exit_code_reporter'
  addReporter = Jasmine::addReporter
  Jasmine::addReporter = (reporter) ->
    addReporter.call this, reporter unless reporter.constructor is ExitCodeReporter
)()

# build

gulp.task 'peg', ->
  gulp.src './app/scripts/fractions-peg-parser.peg'
    .pipe $.peg()
    .on 'error', onError
    .pipe gulp.dest 'app/scripts'

gulp.task 'lint', ->
  gulp.src ['./gulpfile.coffee', './app/**/*.coffee']
    .pipe $.coffeelint()
    .pipe $.coffeelint.reporter()
    .pipe $.coffeelint.reporter 'failOnWarning'

gulp.task 'test', ['peg', 'lint'], ->
  gulp.src 'app/specs/**.coffee'
    .pipe $.jasmine verbose: false

gulp.task 'scripts', ['test'], ->
  browserify = require 'browserify'
  source = require 'vinyl-source-stream'
  buffer = require 'vinyl-buffer'
  coffeeify = require 'coffeeify'

  browserify entries: ['./app/scripts/index.coffee'], extensions: ['.coffee'], debug: true
    .transform(coffeeify)
    .bundle()
    .pipe source 'main.min.js'
    .pipe buffer()
    .pipe $.sourcemaps.init loadMaps: true
    .pipe $.uglify()
    .pipe $.sourcemaps.write './'
    .pipe gulp.dest 'dist/scripts'

gulp.task 'images', ->
  gulp.src 'app/images/*.*'
    .pipe gulp.dest 'dist/images'

gulp.task 'html', ->
  assets = $.useref.assets searchPath: 'app'
  gulp.src 'app/*.html'
    .pipe assets
    .pipe $.if '*.css', $.csso()
    .pipe assets.restore()
    .pipe $.useref()
    .pipe $.if '*.html', $.minifyHtml conditionals: true
    .pipe gulp.dest 'dist'

gulp.task 'extras', -> # currently only for robots.txt
  gulp.src ['app/*.*', '!app/*.html']
    .pipe gulp.dest 'dist'

gulp.task 'clean',
  require 'del'
    .bind null, ['dist', 'app/scripts/*.js']

gulp.task 'build', (done) ->
  run 'clean', ['scripts', 'images', 'html', 'extras'], done

gulp.task 'default', ['build']

# serve

gulp.task 'connect', ['build'], ->
  connect = require 'connect'
  serveStatic = require 'serve-static'
  app = connect()
    .use (require 'connect-livereload') port: 35729
    .use serveStatic 'dist'
    .use '/bower_components', serveStatic './bower_components'

  require 'http'
    .createServer app
    .listen 9000
    .on 'listening', -> $.util.log 'Started connect web server on http://localhost:9000'

gulp.task 'watch', ['connect'], ->
  gulp.watch ['app/**/*.{coffee,js,peg}'], ['scripts']
  gulp.watch ['app/*.html', 'app/styles/**/*.css'], ['html']

  $.livereload.listen()
  gulp.watch ['dist/*.html', 'dist/styles/**/*.css', 'dist/scripts/**/*.coffee', 'dist/scripts/**/*.js']
    .on 'change', $.livereload.changed

gulp.task 'serve', ['watch'], ->
  (require 'opn') 'http://localhost:9000'

# deploy

gulp.task 'cdnize', ['build'], ->
  gulp.src 'dist/index.html'
    .pipe $.cdnizer [
      {
        file: '/bower_components/MathJax/MathJax.js?config=TeX-AMS-MML_HTMLorMML'
        package: 'MathJax'
        cdn: 'http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'
      }
      {
        file: '/bower_components/jquery/dist/jquery.min.js'
        package: 'jquery'
        cdn: 'http://code.jquery.com/jquery-${ version }.min.js'
      }
      {
        file: '/bower_components/bootstrap/dist/css/bootstrap.min.css'
        package: 'bootstrap'
        cdn: 'https://maxcdn.bootstrapcdn.com/bootstrap/${ version }/css/bootstrap.min.css'
      }
    ]
    .pipe gulp.dest './dist'

gulp.task 'deploy', ['cdnize'], ->
  gulp.src 'dist/**/*'
    .pipe $.ghPages()
