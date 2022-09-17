;;; epkg-melpa.el --- Melpa recipes  -*- lexical-binding:t -*-

;; Copyright (C) 2016-2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/emacscollective/epkg
;; Keywords: tools

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'epkg)
(require 'json)

;;; Superclass

(defclass melpa-recipe (closql-object)
  ((closql-table         :initform 'melpa-recipes)
   (closql-primary-key   :initform 'name)
   (closql-foreign-key   :initform 'epkg-package)
   (closql-class-prefix  :initform "melpa-")
   (closql-class-suffix  :initform "-recipe")
   (url-format           :initform nil :allocation :class)
   (repopage-format      :initform nil :allocation :class)
   (name                 :initform nil :initarg :name)
   (url                  :initform nil)
   (repo                 :initform nil)
   (repopage             :initform nil)
   (files                :initform nil)
   (branch               :initform nil)
   (commit               :initform nil)
   (module               :initform nil) ; obsolete
   (version-regexp       :initform nil)
   (old-names            :initform nil)
   (epkg-package         :initform nil))
  :abstract t)

;;; Subclasses

(defclass melpa-git-recipe (melpa-recipe) ())

(defclass melpa--platform-recipe () ())

(defclass melpa-github-recipe (melpa-git-recipe melpa--platform-recipe)
  ((url-format      :initform "git@github.com:%r.git")
   (repopage-format :initform "https://github.com/%r")))

(defclass melpa-gitlab-recipe (melpa-git-recipe melpa--platform-recipe)
  ((url-format      :initform "git@gitlab.com:%r.git")
   (repopage-format :initform "https://gitlab.com/%r")))

(defclass melpa-codeberg-recipe (melpa-git-recipe melpa--platform-recipe)
  ((url-format      :initform "https://codeberg.org/%r.git")
   (repopage-format :initform "https://codeberg.org/%r")))

(defclass melpa-sourcehut-recipe (melpa-git-recipe melpa--platform-recipe)
  ((url-format      :initform "https://git.sr.ht/~%r")
   (repopage-format :initform "https://git.sr.ht/~%r")))

(defclass melpa-hg-recipe (melpa-recipe) ())

;;; Interfaces

(defun melpa-recipes (&optional select predicates)
  (closql-query (epkg-db) select predicates 'melpa-recipe))

(defun melpa-get (name)
  (closql-get (epkg-db) name 'melpa-recipe))

;;; Utilities

(defun melpa-json-recipes ()
  (json-encode (mapcar #'melpa--recipe-plist (melpa-recipes))))

(defun melpa--recipe-plist (rcp)
  (let ((type (melpa--recipe-type rcp)))
    `(,(intern (oref rcp name))
      :fetcher ,type
      ,@(if (memq type '(git hg))
            (list :url (oref rcp url))
          (list :repo (oref rcp repo)))
      ,@(cl-mapcan (lambda (slot)
                     (and-let* ((value (eieio-oref rcp slot)))
                       (list (intern (format ":%s" slot)) value)))
                   '(files branch commit version-regexp old-names)))))

(defun melpa--recipe-type (rcp)
  (intern (substring (symbol-name (eieio-object-class-name rcp)) 6 -7)))

;;; _
(provide 'epkg-melpa)
;;; epkg-melpa.el ends here
