# Hide this file from build
usethis::use_build_ignore("devstuff_history.R")
usethis::use_build_ignore("img")
usethis::use_build_ignore("inst/dev")
usethis::use_build_ignore("rsconnect")
usethis::use_git_ignore("docs/")
usethis::use_git_ignore("rsconnect/")
# usethis::create_package(".")

# description ----

# Licence ----
usethis::use_mit_license("Sébastien Rochette")
# usethis::use_gpl3_license("ThinkR")

# Pipe ----
usethis::use_roxygen_md()
usethis::use_pipe()

# Package quality ----

# _Tests
usethis::use_testthat()
usethis::use_test("app")

# _CI
# usethis::use_travis()
# usethis::use_appveyor()
# usethis::use_coverage()

# _rhub
# rhub::check_for_cran()


# Documentation ----
# _Readme
usethis::use_readme_rmd()
# _News
usethis::use_news_md()
# _Vignette
usethis::use_vignette("ab-model")

# Dependencies ----
# devtools::install_github("ThinkR-open/attachment")
# attachment::att_to_description(extra.suggests = c("bookdown", "pkgdown"))
attachment::att_to_description()
# attachment::create_dependencies_file()

# Description and Bibliography
chameleon::create_pkg_desc_file(out.dir = "inst", source = c("archive"), to = "html")
thinkridentity::create_pkg_biblio_file_thinkr()

# Utils for dev ----
devtools::install(upgrade = "never")
# devtools::load_all()
devtools::check(vignettes = TRUE)
# ascii
stringi::stri_trans_general("é", "hex")
