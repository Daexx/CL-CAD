(in-package :cl-cad)

(defstruct app
  main-window
  data
  view
  current-icon
  current-title
  current-description
  current-view

  filename
  changed)

(defun ensure-data-is-saved (app)
  (if (app-changed app)
      (case (ask-save (app-main-window app)
                      "Save changes before closing? If you don't save, changes will be permanently lost.")
        (:ok
         (cb-save app)
         t)
        (:reject
         t)
        (:cancel
         nil))
      t))

(defun e-close (app)
  (if (ensure-data-is-saved app)
      (progn
        (gtk:gtk-main-quit)
        nil)
      t))

(defun cb-open (app)
  (when (ensure-data-is-saved app)
    (let ((dlg (make-instance 'gtk:file-chooser-dialog
                              :action :open
                              :title "Open file"
                              :window-position :center-on-parent
                              :transient-for (app-main-window app))))

      (gtk:dialog-add-button dlg "gtk-cancel" :cancel)
      (gtk:dialog-add-button dlg "gtk-open" :ok)
      (gtk:set-dialog-alternative-button-order dlg (list :ok :cancel))
      (setf (gtk:dialog-default-response dlg) :ok)
      (when (std-dialog-run dlg)
        (open-file (gtk:file-chooser-filename dlg))))))

(defun cb-save-as (app)
  (let ((dlg (make-instance 'gtk:file-chooser-dialog
                            :action :save
                            :title "Save file"
                            :window-position :center-on-parent
                            :transient-for (app-main-window app))))
    (gtk:dialog-add-button dlg "gtk-cancel" :cancel)
    (gtk:dialog-add-button dlg "gtk-save" :ok)
    (gtk:set-dialog-alternative-button-order dlg (list :ok :cancel))
    (setf (gtk:dialog-default-response dlg) :ok)
    (when (std-dialog-run dlg)
      (setf (app-filename app) (gtk:file-chooser-filename dlg))
      (save-data (gtk:file-chooser-filename dlg)))))

(defun cb-save (app)
  (if (app-filename app)
      (save-data (app-filename app))
      (cb-save-as app)))

(defun cb-new (app)
  (when (ensure-data-is-saved app)
    (setf (app-changed app) nil)
    (setf (app-filename app) nil)))

(defun cb-about (app)
  (let ((dlg (make-instance 'about-dialog
			    :window-position :center-on-parent
			    :transient-for (app-main-window app)
			    :program-name "CL-CAD"
			    :version "0.1"
			    :copyright "Copyright 2010, Burdukov Denis"
			    :comments "Simple CAD program powered by Common-Lisp"
			    :authors '("Burdukov Denis <litetabs@gmail.com>")
			    :license "LGPL"
			    :website "http://cl-cad.blogspot.com")))
    (gtk:dialog-run dlg)
    (gtk:object-destroy dlg)))

(defun cc-expose (widget)
  (multiple-value-bind (w h) (gdk:drawable-get-size (widget-window widget))
    (with-gdk-context (ctx (widget-window widget))
      (with-context (ctx)
        (screen-drawer w h)
        nil))))

(defun main ()
  (load-config)
  (within-main-loop
   (let* ((app (make-app))
	  (main-window (make-instance 'gtk-window :title "CL-CAD" :type :toplevel :window-position :center :default-width 1024 :default-height 600 :app-paintable t))
	  (v-box (make-instance 'v-box))
	  (h-box (make-instance 'h-box))
	  (menu-notebook (make-instance 'notebook :enable-popup t))
	  (draw-area (make-instance 'drawing-area))
	  (toolbar (make-instance 'toolbar :show-arrow t :toolbar-style :icons :tooltips t))
	  (tools-vbox (make-instance 'v-box))
	  (command-entry (make-instance 'entry))
	  (model-width (make-instance 'array-list-store))
	  (model-type (make-instance 'array-list-store))
	  (line-width-combo (make-instance 'combo-box :model model-width))
	  (line-type-combo (make-instance 'combo-box :model model-type))
	  ;;;menu
	  (menubar (make-instance 'menu-bar))
	  (menuitem-file (make-instance 'menu-item 
					:label "File"))
	  (menuitem-edit (make-instance 'menu-item :label "Edit"))
	  (menu-view (make-instance 'menu))
	  (menuitem-view (make-instance 'menu-item :label "View" :submenu menu-view))
	  (menuitem-fullscreen (make-instance 'menu-item :label "Full screen"))
	  (menu-tools (make-instance 'menu))
	  (menuitem-tools (make-instance 'menu-item :label "Tools" :submenu menu-tools))
	  (menuitem-editor (make-instance 'menu-item :label "Editor"))
	  (menuitem-osnap (make-instance 'menu-item :label "Object Snaps"))
 	  (menuitem-about (make-instance 'menu-item :label "About"))
	 ;;;system
	 (button-save (make-instance 'button :image (make-instance 'image :stock "gtk-save")))
	 (button-save-as (make-instance 'button :image (make-instance 'image :stock "gtk-save-as")))
	 (button-new (make-instance 'button :image (make-instance 'image :stock "gtk-new")))
	 (button-open (make-instance 'button :image (make-instance 'image :stock "gtk-open")))
	 (button-print (make-instance 'button :image (make-instance 'image :stock "gtk-print")))
	 (button-print-prop (make-instance 'button :image (make-instance 'image :stock "gtk-page-setup")))
	 (button-system-properties (make-instance 'button :image (make-instance 'image :stock "gtk-properties")))
	 (button-layers (make-instance 'button :image (make-instance 'image :stock "gtk-justify-fill")))
	 (button-file-prop (make-instance 'button :image (make-instance 'image :stock "gtk-preferences")))
	 (button-color-selection (make-instance 'color-button :has-opacity-control t))
	 (button-select-font (make-instance 'font-button :font-name *current-font*))
         ;;;primitives
	 (primitives-expander (make-instance 'expander :expanded t :label "Primitives"))
	 (primitives-table (make-instance 'table :n-rows 5 :n-columns 4 :homogeneous nil))
	 (button-line (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/line.svg" *src-location*)))))
	 (button-ray (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ray.svg" *src-location*)))))
	 (button-construction (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/construction.svg" *src-location*)))))
	 (button-circle-radius (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circleradius.svg" *src-location*)))))
	 (button-circle-2p (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circle2p.svg" *src-location*)))))
	 (button-circle-3p (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circle3p.svg" *src-location*)))))
	 (button-circle-diameter (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circlediameter.svg" *src-location*)))))
	 (button-circle-ttr (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circlettr.svg" *src-location*)))))
	 (button-circle-ttt (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circlettt.svg" *src-location*)))))
	 (button-arc (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/arc3p.svg" *src-location*)))))
	 (button-ellipse-center (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ellipsecenter.svg" *src-location*)))))
	 (button-ellipse-axis (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ellipseaxis.svg" *src-location*)))))
	 (button-ellipse-arc (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ellipsearc.svg" *src-location*)))))
	 (button-pline (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/pline.svg" *src-location*)))))
	 (button-polygon (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/polygon.svg" *src-location*)))))
	 (button-point (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/point.svg" *src-location*)))))
	 (button-rectangle (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/rectangle.svg" *src-location*)))))
	 (button-spline (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/spline.svg" *src-location*)))))
	 (button-text (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/text.svg" *src-location*)))))
         ;;;modify
	 (modify-expander (make-instance 'expander :expanded t :label "Modify"))
	 (modify-table (make-instance 'table :n-rows 3 :n-columns 4 :homogeneous nil))
	 (button-break (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_break.svg" *src-location*)))))
	 (button-erase (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_erase.svg" *src-location*)))))
	 (button-explode (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_explode.svg" *src-location*)))))
	 (button-extend (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_extend.svg" *src-location*)))))
	 (button-lengthen (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_lengthen.svg" *src-location*)))))
	 (button-move (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_move.svg" *src-location*)))))
	 (button-rotate (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_rotate.svg" *src-location*)))))
	 (button-scale (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_scale.svg" *src-location*)))))
	 (button-stretch (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_stretch.svg" *src-location*)))))
	 (button-trim (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_trim.svg" *src-location*)))))
         ;;;dimension
	 (dimension-expander (make-instance 'expander :expanded t :label "Dimension"))
	 (dimension-table (make-instance 'table :n-rows 3 :n-columns 4 :homogeneous nil))
	 (button-align (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimalign.svg" *src-location*)))))
	 (button-angular (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimangular.svg" *src-location*)))))
	 (button-baseline (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimbaseline.svg" *src-location*)))))
	 (button-center (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimcenter.svg" *src-location*)))))
	 (button-continue (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimcontinue.svg" *src-location*)))))
	 (button-diameter (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimdiameter.svg" *src-location*)))))
	 (button-horiz (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimhoriz.svg" *src-location*)))))
	 (button-leader (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimleader.svg" *src-location*)))))
	 (button-vert (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimvert.svg" *src-location*)))))
	 ;;;construct
	 (construct-expander (make-instance 'expander :expanded t :label "Construct"))
	 (construct-table (make-instance 'table :n-rows 2 :n-columns 4 :homogeneous nil))
	 (button-array-polar (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_array_polar.svg" *src-location*)))))
	 (button-array-rect (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_array_rect.svg" *src-location*)))))
	 (button-chamfer (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_chamfer.svg" *src-location*)))))
	 (button-copy (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_copy.svg" *src-location*)))))
	 (button-fillet (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_fillet.svg" *src-location*)))))
	 (button-mirror (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_mirror.svg" *src-location*)))))
	 (button-offset (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_offset.svg" *src-location*)))))
	 (full-window nil))
     (container-add main-window v-box)
     (box-pack-start v-box menubar :expand nil)
     (container-add menubar menuitem-file)
     (container-add menubar menuitem-edit)
     (container-add menubar menuitem-view)
     (container-add menu-view menuitem-fullscreen)
     (container-add menubar menuitem-tools)
     (container-add menu-tools menuitem-editor)
     (container-add menu-tools menuitem-osnap)
     (container-add menubar menuitem-about)
     (box-pack-start v-box toolbar :expand nil)
     (container-add v-box h-box)
     (box-pack-start h-box menu-notebook :expand nil)
     (box-pack-start h-box draw-area :expand t)
     (box-pack-start v-box command-entry :expand nil)
     (notebook-add-page menu-notebook
			tools-vbox
			(make-instance 'label :label "Tools"))
     (notebook-add-page menu-notebook
			(make-instance 'v-box)
			(make-instance 'label :label "Files"))
     (notebook-add-page menu-notebook
			(make-instance 'v-box)
			(make-instance 'label :label "Statistic"))
     ;system 
     (container-add toolbar button-save)
     (container-add toolbar button-save-as)
     (container-add toolbar button-new)
     (container-add toolbar button-open)
     (container-add toolbar button-print)
     (container-add toolbar button-print-prop)
     (container-add toolbar button-file-prop)
     (container-add toolbar button-layers)
     (container-add toolbar button-system-properties)
     (container-add toolbar button-color-selection)
     (container-add toolbar button-select-font)
     (container-add toolbar line-width-combo)
     (container-add toolbar line-type-combo)
     ;primitives
     (box-pack-start tools-vbox primitives-expander :expand nil)
     (container-add primitives-expander primitives-table)
     (table-attach primitives-table button-line 0 1 0 1)
     (table-attach primitives-table button-ray 1 2 0 1)
     (table-attach primitives-table button-construction 2 3 0 1)
     (table-attach primitives-table button-circle-radius 3 4 0 1)
     (table-attach primitives-table button-circle-2p 0 1 1 2)
     (table-attach primitives-table button-circle-3p 1 2 1 2)
     (table-attach primitives-table button-circle-diameter 2 3 1 2)
     (table-attach primitives-table button-circle-ttr 3 4 1 2)
     (table-attach primitives-table button-circle-ttt 0 1 2 3)
     (table-attach primitives-table button-arc 1 2 2 3)
     (table-attach primitives-table button-ellipse-center 2 3 2 3)
     (table-attach primitives-table button-ellipse-axis 3 4 2 3)
     (table-attach primitives-table button-ellipse-arc 0 1 3 4)
     (table-attach primitives-table button-pline 1 2 3 4)
     (table-attach primitives-table button-polygon 2 3 3 4)
     (table-attach primitives-table button-point 3 4 3 4)
     (table-attach primitives-table button-rectangle 0 1 4 5)
     (table-attach primitives-table button-spline 1 2 4 5)
     (table-attach primitives-table button-text 2 3 4 5)
     ;modify
     (box-pack-start tools-vbox modify-expander :expand nil)
     (container-add modify-expander modify-table)
     (table-attach modify-table button-break 0 1 0 1)
     (table-attach modify-table button-erase 1 2 0 1)
     (table-attach modify-table button-explode 2 3 0 1)
     (table-attach modify-table button-extend 3 4 0 1)
     (table-attach modify-table button-lengthen 0 1 1 2)
     (table-attach modify-table button-move 1 2 1 2)
     (table-attach modify-table button-rotate 2 3 1 2)
     (table-attach modify-table button-scale 3 4 1 2)
     (table-attach modify-table button-stretch 0 1 2 3)
     (table-attach modify-table button-trim 1 2 2 3)
     ;dimension
     (box-pack-start tools-vbox dimension-expander :expand nil)
     (container-add dimension-expander dimension-table)
     (table-attach dimension-table button-align 0 1 0 1)
     (table-attach dimension-table button-angular 1 2 0 1)
     (table-attach dimension-table button-baseline 2 3 0 1)
     (table-attach dimension-table button-center 3 4 0 1)
     (table-attach dimension-table button-continue 0 1 1 2)
     (table-attach dimension-table button-diameter 1 2 1 2)
     (table-attach dimension-table button-horiz 2 3 1 2)
     (table-attach dimension-table button-leader 3 4 1 2)
     (table-attach dimension-table button-vert 0 1 2 3)
     ;construct
     (box-pack-start tools-vbox construct-expander :expand nil)
     (container-add construct-expander construct-table)
     (table-attach construct-table button-array-polar 0 1 0 1)
     (table-attach construct-table button-array-rect 1 2 0 1)
     (table-attach construct-table button-chamfer 2 3 0 1)
     (table-attach construct-table button-copy 3 4 0 1)
     (table-attach construct-table button-fillet 0 1 1 2)
     (table-attach construct-table button-mirror 1 2 1 2)
     (table-attach construct-table button-offset 2 3 1 2)
     (setf (app-main-window app) main-window)
     (let ((renderer (make-instance 'cell-renderer-text :text "A text")))
        (cell-layout-pack-start line-width-combo renderer :expand t)
        (cell-layout-add-attribute line-width-combo renderer "text" 0))
     (let ((renderer (make-instance 'cell-renderer-text :text "A text")))
        (cell-layout-pack-start line-type-combo renderer :expand t)
        (cell-layout-add-attribute line-type-combo renderer "text" 0))
     ;;;g-signals
     (gobject:g-signal-connect (app-main-window app) "destroy" (lambda (b) (declare (ignore b)) (e-close app)))
     (gobject:g-signal-connect draw-area "motion-notify-event" (lambda (widget event)
								 (declare (ignore widget))
			  					 (setf *current-x* (gdk:event-motion-x event)
								       *current-y* (gdk:event-motion-y event))
								 (widget-queue-draw draw-area)))
     (gobject:g-signal-connect draw-area "button-press-event" (lambda (widget event)
								(declare (ignore widget))
								(if (equal *end* 0)
								    (setf *x* *current-x*
									  *y* *current-y*))
								(setf *end* (1+ *end*))
								(widget-queue-draw draw-area)))
     (gobject:g-signal-connect draw-area "scroll-event" (lambda (object event)
								 (declare (ignore object))
								  (if (equal (gdk:event-scroll-direction event) :UP)
								      (setf *scroll-units* (+ *scroll-units* 0.1))
								      (setf *scroll-units* (/ *scroll-units* 1.1)))
								  (widget-queue-draw draw-area)))
     (gobject:g-signal-connect draw-area "expose-event" (lambda (widget event)
							  (declare (ignore widget event))
							  (cc-expose draw-area)))
     (gobject:g-signal-connect draw-area "configure-event" (lambda (widget event)
							     (declare (ignore widget event))
							     (widget-queue-draw draw-area)))
     (gobject:g-signal-connect draw-area "realize" (lambda (object)
						     (declare (ignore object))
						     (pushnew :button-press-mask (gdk:gdk-window-events (widget-window draw-area)))))
     (gobject:g-signal-connect button-save "clicked" (lambda (w) (declare (ignore w)) (cb-save app)))
     (gobject:g-signal-connect button-save-as "clicked" (lambda (w) (declare (ignore w)) (cb-save-as app)))
     (gobject:g-signal-connect button-new "clicked" (lambda (w) (declare (ignore w)) (cb-new app)))
     (gobject:g-signal-connect button-open "clicked" (lambda (w) (declare (ignore w)) (cb-open app)))
  ;   (gobject:g-signal-connect button-print "clicked" (lambda (w) (declare (ignore w)) ))
     (gobject:g-signal-connect button-print-prop "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-file-prop "clicked" (lambda (w) (declare (ignore w)) (file-properties-window (app-main-window app))))
     (gobject:g-signal-connect button-color-selection "color-changed" (lambda (s) (declare (ignore s)) 
									      (unless (color-selection-adjusting-p button-color-selection) 
										(format t "color: ~A~%" (color-selection-current-color button-color-selection)))))
     (gobject:g-signal-connect button-select-font "font-set" (lambda (b) (declare (ignore b)) (setf *current-font* (font-button-font-name button-select-font))))
     (gobject:g-signal-connect button-system-properties "clicked" (lambda (w) (declare (ignore w)) (draw-properties-window (app-main-window app))))
     (gobject:g-signal-connect button-layers "clicked" (lambda (w) (declare (ignore w)) (layers-window (app-main-window app))))
     (gobject:g-signal-connect button-line "clicked" (lambda (w) (declare (ignore w))
							     (setf *end* 0)
							     (setf *x* 0 *y* 0)
							     (setf *signal* :line)))
     (gobject:g-signal-connect button-ray "clicked" (lambda (w) (declare (ignore w))
							    (setf *end* 0)
							    (setf *x* 0 *y* 0)
							    (setf *signal* :ray)))
     (gobject:g-signal-connect button-construction "clicked" (lambda (w) (declare (ignore w))
								     (setf *x* 0 *y* 0)
								     (setf *end* 0)
								     (setf *signal* :continious)))
     (gobject:g-signal-connect button-circle-radius "clicked" (lambda (w) (declare (ignore w))
								      (setf *end* 0)
								      (setf *x* 0 *y* 0)
								      (setf *signal* :circle)))
     (gobject:g-signal-connect button-circle-2p "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-3p "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-diameter "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-ttr "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-ttt "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-arc "clicked" (lambda (w) (declare (ignore w))
							     (setf *end* 0)
							     (setf *x* 0 *y* 0)
							     (setf *signal* :arc)))
     (gobject:g-signal-connect button-ellipse-center "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-ellipse-axis "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-ellipse-arc "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-pline "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-polygon "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-point "clicked" (lambda (w) (declare (ignore w))
							      (setf *x* 0 *y* 0)
							      (setf *end* 0)
							      (setf *signal* :point)))
     (gobject:g-signal-connect button-rectangle "clicked" (lambda (w) (declare (ignore w)) 
								  (setf *x* 0 *y* 0)
								  (setf *end* 0)
								  (setf *signal* :rectangle)))
     (gobject:g-signal-connect button-spline "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-text "clicked" (lambda (w) (declare (ignore w))
							     (entry-window (app-main-window app))
							     (setf *x* 0 *y* 0)
							     (setf *end* 0)
							     (setf *signal* :text)))
     (gobject:g-signal-connect button-break "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-erase "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-explode "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-extend "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-lengthen "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-move "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-rotate "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-trim "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-align "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-horiz "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-leader "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-vert "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect menuitem-about "activate" (lambda (w) (declare (ignore w)) (cb-about app)))
     (gobject:g-signal-connect menuitem-editor "activate" (lambda (w) (declare (ignore w)) (code-editor (app-main-window app))))
     (gobject:g-signal-connect menuitem-osnap "activate" (lambda (b) (declare (ignore b)) (osnap-window (app-main-window app))))
     (gobject:g-signal-connect menuitem-fullscreen "activate" (lambda (b) (declare (ignore b))
								      (if (equal full-window nil)
									  (progn (gtk-window-fullscreen (app-main-window app)) (setf full-window t))
									  (progn (gtk-window-unfullscreen (app-main-window app)) (setf full-window nil)))))
     (widget-show (app-main-window app))
     (push :pointer-motion-mask (gdk-window-events (widget-window draw-area)))
     (push :scroll-mask (gdk-window-events (widget-window draw-area)))
     (push :button-press-mask (gdk-window-events (widget-window draw-area)))))
  (save-config))

(export 'main)



(defun main-and-quit ()
  (main)
  #+sbcl(sb-ext:quit)
  #+clozure(ccl:quit))

(export 'main-and-quit)