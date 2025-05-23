#' Plot simulated fossils
#'
#' @description
#' This function is adapted from the \emph{ape} function \code{plot.phylo} used to plot phylogenetic trees.
#' The function can be used to plot simulated fossils (\code{show.fossils = TRUE}), with or without the corresponding tree (\code{show.tree = TRUE}),
#' stratigraphic intervals (\code{show.strata = TRUE}), stratigraphic ranges (\code{show.ranges = TRUE}) and sampling proxy data (\code{show.proxy = TRUE}).
#' Interval ages can be specified as a vector (\code{interval.ages}) or a uniform set of interval ages can be specified using the
#' number of intervals (\code{strata}) and maximum interval age (\code{max}), where interval length \eqn{= max.age/strata}.
#' If no maximum age is specified, the function calculates a maximum interval age slightly older than the root edge (or root age if \code{root.edge = FALSE}),
#' using the function \code{tree.max()}.
#'
#' @param x Fossils object.
#' @param tree Phylo object.
#' @param show.fossils If TRUE plot fossils (default = TRUE).
#' @param show.tree If TRUE plot the tree  (default = TRUE).
#' @param show.ranges If TRUE plot stratigraphic ranges (default = FALSE). If \code{show.taxonomy = FALSE} all occurrences along a single edge are grouped together (i.e. function assumes all speciation is symmetric).
#' @param show.strata If TRUE plot strata  (default = FALSE).
#' @param interval.ages Vector of stratigraphic interval ages, starting with the minimum age of the youngest interval and ending with the maximum age of the oldest interval.
#' @param strata Number of stratigraphic intervals (default = 1).
#' @param max.age Maximum age of a set of equal length intervals. If no value is specified (\code{max = NULL}), the function uses a maximum age based on tree height.
#' @param show.axis If TRUE plot x-axis (default = TRUE).
#' @param binned If TRUE fossils are plotted at the mid point of each interval.
#' @param show.proxy If TRUE add profile of sampling data to plot (e.g. rates in time-dependent rates model) (default = FALSE).
#' @param proxy.data Vector of sampling proxy data (default = NULL). Should be as long as the number of stratigraphic intervals.
#' @param show.preferred.environ If TRUE add species preferred environmental value (e.g. water depth) (default = FALSE). Only works if combined with \code{show.proxy = TRUE}.
#' @param preferred.environ Preferred environmental value (e.g. water depth). Currently only one value can be shown.
#' @param show.taxonomy If TRUE highlight species taxonomy.
#' @param taxonomy Taxonomy object.
#' @param show.unknown If TRUE plot fossils with unknown taxonomic affiliation (i.e. sp = NA) (default = FALSE).
#' @param rho Extant species sampling probability (default = 1). Will be disregarded if fossils object already contains extant samples.
#' @param reconstructed If TRUE plot the reconstructed tree. If fossils object contains no extant samples, the function assumes rho = 1 and includes all species at the present.
#' @param root.edge If TRUE include the root edge (default = TRUE).
#' @param hide.edge If TRUE hide the root edge but still incorporate it into the automatic timescale (default = FALSE).
#' @param edge.width A numeric vector giving the width of the branches of the plotted phylogeny. These are taken to be in the same order as the component edge of \code{tree}. If fewer widths are given than the number of edges, then the values are recycled.
#' @param show.tip.label Whether to show the tip labels on the phylogeny (defaults to FALSE).
#' @param align.tip.label A logical value or an integer. If TRUE, the tips are aligned and dotted lines are drawn between the tips of the tree and the labels. If an integer, the tips are aligned and this gives the type of the lines (following \code{lty}).
#' @param fossil.col Colour of fossil occurrences. A vector equal to the length of the fossils object can be used to assign different colours.
#' @param range.col Colour of stratigraphic ranges.
#' @param extant.col Colour of extant samples. If \code{show.taxonomy = TRUE}, \code{extant.col} will be ignored.
#' @param taxa.palette Colour palette used if \code{show.fossils = TRUE}. Colours are assigned to taxa using the function \code{grDevices::hcl.colors()} and the default palette is "viridis". Other colour blind friendly palettes include \code{"Blue-Red 3"} and \code{"Green-Brown"}.
#' @param col.axis Colour of the time scale axis (default = "gray35").
#' @param cex Numeric value giving the factor used to scale the points representing the fossils when \code{show.fossils = TRUE}.
#' @param pch Numeric value giving the symbol used for the points representing the fossils when \code{show.fossils = TRUE}.
#' @param t.axis.lab Axis label for the time (x) axis
#' @param ... Additional parameters to be passed to \code{plot.default}.
#'
#' @examples
#' set.seed(123)
#'
#' ## simulate tree
#' t = TreeSim::sim.bd.taxa(8, 1, 1, 0.3)[[1]]
#'
#' ## simulate fossils under a Poisson sampling process
#' f = sim.fossils.poisson(rate = 3, tree = t)
#' plot(f, t)
#' # add a set of equal length strata
#' plot(f, t, show.strata = TRUE, strata = 4)
#' # show stratigraphic ranges
#' plot(f, t, show.strata = TRUE, strata = 4, show.ranges = TRUE)
#'
#' ## simulate fossils and highlight taxonomy
#' s = sim.taxonomy(t, 0.5, 1)
#' f = sim.fossils.poisson(rate = 3, taxonomy = s)
#' plot(f, t, taxonomy = s, show.taxonomy = TRUE, show.ranges = TRUE)
#'
#'
#' ## simulate fossils under a non-uniform model of preservation
#' # assign a max interval based on tree height
#' max.age = tree.max(t)
#' times = c(0, 0.3, 1, max.age)
#' rates = c(4, 1, 0.1)
#' f = sim.fossils.intervals(t, interval.ages = times, rates = rates)
#' plot(f, t, show.strata = TRUE, interval.ages = times)
#' # add proxy data
#' plot(f, t, show.strata = TRUE, interval.ages = times, show.proxy = TRUE, proxy.data = rates)
#'
#' @export
#' @importFrom graphics par points lines text axis mtext segments rect plot
#' @importFrom grDevices colors rgb adjustcolor
#' @importFrom stats na.omit
plot.fossils = function(x, tree, show.fossils = TRUE, show.tree = TRUE, show.ranges = FALSE,
                        # age info/options
                        show.strata = FALSE, strata = 1, max.age = NULL, interval.ages = NULL, binned = FALSE, show.axis = TRUE,
                        # proxy stuff
                        show.proxy = FALSE, proxy.data = NULL,
                        show.preferred.environ = FALSE, preferred.environ = NULL,
                        # taxonomy
                        show.taxonomy = FALSE, taxonomy = NULL, show.unknown = FALSE, rho = 1,
                        # tree appearance
                        root.edge = TRUE, hide.edge = FALSE, edge.width = 1, show.tip.label = FALSE, align.tip.label = FALSE, reconstructed = FALSE,
                        # fossil appearance
                        fossil.col = 1, range.col = rgb(0,0,1), extant.col = 1, taxa.palette = "viridis",
                        col.axis = "gray35", cex = 1.2, pch = 18, t.axis.lab = "Time before present", ...) {

  fossils = x

  # hard coded options for tree appearance
  edge.color = "black"
  edge.lty = 1
  font = 3 # italic
  tip.color = "black"
  label.offset = 0.02
  align.tip.label.lty = 3
  underscore = FALSE
  plot = TRUE
  node.depth = 1
  no.margin = FALSE
  adj = NULL
  srt = 0

  if(!show.tree) align.tip.label = TRUE

  if(!(is.fossils(fossils)))
    stop("fossils must be an object of class \"fossils\"")

  if(!"phylo" %in% class(tree))
    stop("tree must be an object of class \"phylo\"")

  if(!all( as.vector(na.omit(fossils$edge)) %in% tree$edge))
    stop("Mismatch between fossils and tree objects")

  if(!(rho >= 0 && rho <= 1))
    stop("rho must be a probability between 0 and 1")

  # tolerance for extant tips and interval/ fossil age comparisons
  tol = min((min(tree$edge.length)/100), 1e-8)

  # If there are no extant samples, simulate extant samples
  if(!any( abs(fossils$hmax) < tol )){
    fossils = sim.extant.samples(fossils, tree = tree, rho = rho)
  }

  if(is.null(tree$root.edge))
    root.edge = FALSE

  if(is.null(max.age))
    ba = tree.max(tree, root.edge = root.edge)
  else ba = max.age

  offset = 0 # distance from youngest tip to present
  if(!is.null(tree$origin.time)) offset = min(n.ages(tree))

  # note max.age defined above based on the complete tree
  if(reconstructed){
    out = reconstructed.tree.fossils.objects(fossils, tree)
    fossils = out$fossils
    tree = out$tree
    if(is.null(tree$root.edge)) root.edge = FALSE
  }

  # check the tree
  Ntip <- length(tree$tip.label)
  if (Ntip < 2) {
    warning("found less than 2 tips in the tree")
    return(NULL)
  }

  if (any(tabulate(tree$edge[, 1]) == 1))
    stop("there are single (non-splitting) nodes in your tree; you may need to use collapse.singles()")

  if(!ape::is.rooted(tree))
    stop("tree must be rooted")

  if(is.null(tree$edge.length))
    stop("tree must have edge lengths")

  Nnode <- tree$Nnode
  if (any(tree$edge < 1) || any(tree$edge > Ntip + Nnode))
    stop("tree badly conformed; cannot plot. Check the edge matrix.")
  ROOT <- Ntip + 1

  # check interval ages & proxy data
  if(any(fossils$hmin != fossils$hmax)) binned = TRUE

  if(show.strata || show.proxy){
    if( (is.null(interval.ages)) && (is.null(strata)) )
      stop("To plot interval info specify interval.ages OR number of strata, else use show.strata = FALSE")
  }

  if(show.proxy && is.null(proxy.data))
    stop("Specify sampling profile")

  if(show.proxy){
    if(!is.null(interval.ages)){
      if( (length(interval.ages) - 1) != length(proxy.data) )
        stop("Make sure number of sampling proxy data points matches the number of intervals")
    } else {
      if(strata != length(proxy.data))
        stop("Make sure number of sampling proxy data points matches the number of intervals")
    }
    if(any(is.na(proxy.data)))
      stop("Function can't handle NA proxy values right now, please use 0")
  }

  # check taxonomy data
  if(show.taxonomy && is.null(taxonomy))
    stop("Specify taxonomy using \"taxonomy\"")
  if(show.taxonomy && !"taxonomy" %in% class(taxonomy))
    stop("taxonomy must be an object of class \"taxonomy\"")
  if(show.taxonomy && !all(fossils$edge %in% taxonomy$edge))
    stop("Mismatch between fossils and taxonomy objects")
  if(show.taxonomy && !all(tree$edge %in% taxonomy$edge))
    stop("Mismatch between tree and taxonomy objects")

  # collect data for plotting the tree
  type = "phylogram"
  direction = "rightwards"
  horizontal = TRUE # = "rightwards"

  xe = tree$edge # used in the last part of the fxn
  yy = numeric(Ntip + Nnode)
  TIPS = tree$edge[tree$edge[, 2] <= Ntip, 2]
  yy[TIPS] = 1:Ntip

  yy = ape::node.height(tree)
  xx = ape::node.depth.edgelength(tree)

  if(root.edge)
    xx = xx + tree$root.edge

  # x.lim is defined by max(ba, tree age)
  if(ba - offset > max(xx))
    xx = xx + (ba - offset - max(xx))

  x.lim = c(0, NA)
  pin1 = par("pin")[1]
  strWi = graphics::strwidth(tree$tip.label, "inches", cex = par("cex"))
  xx.tips = xx[1:Ntip] * 1.04
  alp = try(stats::uniroot(function(a) max(a * xx.tips + strWi) - pin1, c(0, 1e+06))$root, silent = TRUE)
  if (is.character(alp)) {
    tmp = max(xx.tips)
    if (show.tip.label)
      tmp = tmp * 1.5
  } else {
    tmp = if (show.tip.label)
      max(xx.tips + strWi/alp)
    else max(xx.tips)
  }
  if (show.tip.label)
    tmp = tmp + label.offset
  x.lim[2] = tmp

  if(show.unknown)
    y.lim = c(0, Ntip)
  else y.lim = c(1, Ntip)

  use.species.ages = FALSE

  # define interval ages
  if(show.strata || show.axis || binned || show.proxy){
    if( (is.null(interval.ages)) ){
      s1 = (ba - offset) / strata # horizon length (= max age of youngest horizon)
      horizons.max = seq(s1 + offset, ba, length = strata)
      horizons.min = horizons.max - s1
      s1 = horizons.max - horizons.min
    } else {
      horizons.min = utils::head(interval.ages, -1)
      horizons.max = interval.ages[-1]
      ba = max(horizons.max)
      s1 = rev(horizons.max - horizons.min)
      strata = length(horizons.max)
    }
    # the following is to catch datasets with hmin != hmax combinations that differ from user specified interval bounds
    if(binned & any(fossils$hmax != fossils$hmin)){
      if(length( unlist( sapply(fossils$hmax, function(x){
        if(x < tol) return(1)
        which(abs(horizons.max - x) < tol) }))) != length(fossils$hmax)){
        use.species.ages = TRUE
        binned = FALSE
      }
    }
  }

  # the order in which you use plot and par here is very important
  if(show.proxy){
    old.par = par("usr", "mar", "oma", "xpd", "mgp","fig")
    par(mar=c(1, 3.5, 0, 0.5)) # to reduce the margins around each plot - bottom, left, top, right -- this is harder to manipulate
    par(oma=par("oma") + c(2, 0, 2, 0)) # to add an outer margin to the top and bottom of the graph -- bottom, left, top, right
    par(xpd=NA) # allow content to protrude into outer margin (and beyond)
    par(mgp=c(1.5, .5, 0)) # to reduce the spacing between the figure plotting region and the axis labels -- axis label at 1.5 rows distance, tick labels at .5 row
    par(fig=c(0,1,0,0.4))
    graphics::plot.default(0, type = "n", xlim = x.lim, ylim = y.lim, xlab = "", ylab = "", axes = FALSE, asp = NA, ...)
    par(fig=c(0,1,0.4,1))
  }
  else{
    old.par = par("xpd", "mar")
    par(xpd=NA)
    par(mar=c(5,4,2.5,2) + 0.1) ## default is c(5,4,4,2) + 0.1
    # open a new plot window
    graphics::plot.default(0, type = "n", xlim = x.lim, ylim = y.lim, xlab = "", ylab = "", axes = FALSE, asp = NA, ...)

  }

  if (plot) {

    # add colored strata
    # rect(xleft, ybottom, xright, ytop)
    if(show.strata || show.axis || show.proxy){

      # y-axis:
      #y.bottom = 0
      #y.top = max(yy)+1
      y.bottom = 0.5
      y.top = max(yy) + 0.5

      # x-axis:
      #s1 = ba / strata
      x.left = 0 - (ba - offset - max(xx))
      x.right = x.left + s1[1]
      cc = 1 # color switch

      axis.strata = x.left

      for(i in 1:strata){
        if(cc %% 2 == 0)
          col="grey90"
        else
          col="grey95"
        if(show.strata)
          rect(xleft = x.left, xright = x.right, ybottom = y.bottom, ytop = y.top, col=col, border=NA)
        x.left = x.right
        x.right = x.left + s1[i+1]
        cc = cc + 1
        axis.strata = c(axis.strata, x.left)
      }

      x.labs = rev(round(c(offset, horizons.max),2))

      if(show.proxy)
        labs = FALSE
      else
        labs = x.labs

      if(show.axis){
        axis(1, col = col.axis, at = axis.strata, labels = labs, lwd = 2, line = 0.5, col.axis = col.axis, cex.axis = .9)
        if(!show.proxy)
          mtext(1, col = 'grey35', text=t.axis.lab, line = 3, cex = 1.2)
      }
    }

    # plot the tree
    if(show.tree)
      ape::phylogram.plot(tree$edge, Ntip, Nnode, xx, yy, horizontal, edge.color, edge.width, edge.lty)

    # format the root edge
    if (root.edge && show.tree && !hide.edge) {
      rootcol = if(length(edge.color) == 1)
        edge.color
      else "black"
      rootw = if(length(edge.width) == 1)
        edge.width
      else 1
      rootlty = if(length(edge.lty) == 1)
        edge.lty
      else 1

      # plot the root edge
      segments(xx[ROOT] - tree$root.edge, yy[ROOT], xx[ROOT], yy[ROOT], col = rootcol, lwd = rootw, lty = rootlty)
    }

    # format tip labels
    if (show.tip.label) {

      # x and y co-ordinates
      adj = 0
      MAXSTRING <- max(graphics::strwidth(tree$tip.label, cex = cex))
      loy <- 0
      lox <- label.offset + MAXSTRING * 1.05 * adj

      if (is.expression(tree$tip.label))
        underscore <- TRUE
      if (!underscore)
        tree$tip.label <- gsub("_", " ", tree$tip.label)

      if (align.tip.label) {
        xx.tmp <- max(xx[1:Ntip])
        yy.tmp <- yy[1:Ntip]
        segments(xx[1:Ntip], yy[1:Ntip], xx.tmp, yy.tmp, lty = align.tip.label.lty)
      }
      else {
        xx.tmp <- xx[1:Ntip]
        yy.tmp <- yy[1:Ntip]
      }
      text(xx.tmp + lox, yy.tmp + loy, tree$tip.label,adj = adj, font = font, srt = srt, cex = cex, col = tip.color)
    }

    if(length(fossils$sp)){
      # binned but assigned to an independent set of interval ages
      if(use.species.ages)
        fossils$h = (fossils$hmax - fossils$hmin)/2 + fossils$hmin
      # not binned
      else if(!binned) fossils$h = fossils$hmin
      # binned & already assigned to intervals
      else if (binned & any(fossils$hmin != fossils$hmax))
        fossils$h = fossils$hmax
      # binned but not assigned to intervals
      else if(binned & all(fossils$hmin == fossils$hmax))
        fossils$h = sim.interval.ages(fossils, tree, interval.ages = c(0, horizons.max))$hmax

      fossils$col = fossil.col

      # taxonomy colours
      if(show.taxonomy){
        sps = unique(fossils$sp)
        col = grDevices::hcl.colors(length(sps), palette = taxa.palette)
        j = 0
        for(i in sps){
          j = j + 1
          fossils$col[which(fossils$sp == i)] = col[j]
        }
      }

      fossils$col[which(fossils$h < tol)] = extant.col

      if(show.fossils || show.ranges){
        if(binned) {
          fossils$r = sapply(fossils$h - offset, function(x) {
            if(x < tol) return(max(xx) - x)
            y = max(which(abs(horizons.max - x) < tol))
            max(xx) - horizons.max[y] + (rev(s1)[y]/2) })
        } else {
          fossils$r = max(xx) - fossils$h + offset
        }
      }

      # fossils unaffiliated with taxonomy
      if( show.unknown && any(is.na(fossils$sp)) ){
        unknownx = fossils[ which(is.na(fossils$sp)), ]$r
        unknowny = rep(0, length(unknownx))
        points(unknownx, unknowny, cex = cex, pch = pch, col = fossil.col)
        fossils = na.omit(fossils)
      }

      # fossils
      if(show.fossils & !show.ranges){
        points(fossils$r, yy[fossils$edge], cex = cex, pch = pch, col = fossils$col)
      }

      # ranges
      if(show.ranges){

        # for show.taxonomy = TRUE
        # fetch oldest and youngest edge associated with a species
        # deal with the oldest part of the ranges
        # deal with the youngest part of the ranges
        # everyting inbetween
        if(show.taxonomy){

          for(i in unique(fossils$sp)){

            mn = min(fossils$h[which(fossils$sp == i)])
            mx = max(fossils$h[which(fossils$sp == i)])
            edge.mn = fossils$edge[which(fossils$sp == i & fossils$h == mn)]
            edge.mx = fossils$edge[which(fossils$sp == i & fossils$h == mx)]

            edges = find.edges.inbetween(edge.mn, edge.mx, tree)

            col = fossils$col[which(fossils$sp == i)]

            for(j in edges){

              # singletons
              if(mn == mx) {
                range = fossils$r[which(fossils$edge == edge.mn & fossils$sp == i)]
              }

              # single edge
              else if(edge.mn == edge.mx) range = fossils$r[which(fossils$edge == edge.mn
                                                                  & fossils$sp == i)]

              # multiple edges: FA edge
              else if(j == edge.mx) {
                range =  c(fossils$r[which(fossils$edge == edge.mx & fossils$sp == i)],
                           max(xx) + offset - taxonomy$end[which(taxonomy$edge == j & taxonomy$sp == i)])
              }
              # multiple edges: LA edge
              else if(j == edge.mn){
                range =  c(fossils$r[which(fossils$edge == edge.mn & fossils$sp == i)],
                           max(xx) + offset - taxonomy$start[which(taxonomy$edge == j & taxonomy$sp == i)])
              }
              # multiple edges: in-between edges
              else{
                range =  c(max(xx) + offset - taxonomy$start[which(taxonomy$edge == j & taxonomy$sp == i)],
                           max(xx) + offset - taxonomy$end[which(taxonomy$edge == j & taxonomy$sp == i)])
              }
              # plot ranges
              sp = yy[j]

              w = 0.1

              # plot ranges & fossils
              if(length(range) > 1){
                rect(min(range), sp+w, max(range), sp-w, col=adjustcolor(col, alpha.f = 0.3))
                if(show.fossils)
                  points(range, rep(sp, length(range)), cex = cex, pch = pch, col = col)
                else
                  points(c(min(range), max(range)), c(sp, sp), cex = cex, pch = pch, col = col)
              } else # plot singletons
                points(range, sp, cex = cex, pch = pch, col = col)

            }
          }
        } else{
          for(i in unique(fossils$edge)) {

            range = fossils$r[which(fossils$edge == i)]

            sp = yy[i]

            w = 0.1

            # plot ranges & fossils
            if(length(range) > 1){
              rect(min(range), sp+w, max(range), sp-w, col=adjustcolor(range.col, alpha.f = 0.2))
              if(show.fossils)
                points(range, rep(sp, length(range)), cex = cex, pch = pch, col = fossil.col)
              else
                points(c(min(range), max(range)), c(sp, sp), cex = cex, pch = pch, col = fossil.col)
            } else # plot singletons
              points(range, sp, cex = cex, pch = pch, col = fossil.col)
          }
        }
      }
      fossils$r = NULL
    }

    # water depth profile
    add.depth.axis = TRUE
    if(show.proxy){
      add.depth.profile(proxy.data, axis.strata, strata, show.axis, add.depth.axis,
                        show.preferred.depth = show.preferred.environ, PD = preferred.environ, x.labs = x.labs,
                        t.axis.lab = t.axis.lab)
    }
  }

  if(!is.na(old.par[1])) par(old.par)
  L <- list(type = type, use.edge.length = TRUE,
            node.pos = NULL, node.depth = node.depth, show.tip.label = show.tip.label,
            show.node.label = FALSE, font = font, cex = cex,
            adj = adj, srt = srt, no.margin = no.margin, label.offset = label.offset,
            x.lim = x.lim, y.lim = y.lim, direction = direction,
            tip.color = tip.color, Ntip = Ntip, Nnode = Nnode, root.time = tree$root.time,
            align.tip.label = align.tip.label)
  assign("last_plot.phylo", c(L, list(edge = xe, xx = xx, yy = yy)),
         envir = ape::.PlotPhyloEnv)
  invisible(L)
}

add.depth.profile = function(depth.profile, axis.strata, strata, show.axis, add.depth.axis, show.preferred.depth = TRUE, PD = NULL, x.labs = FALSE, t.axis.lab){
  par(fig = c(0,1,0,0.4), new = T)
  # change the y-axis scale for depth
  u = par("usr") # current scale
  depth.profile = rev(depth.profile)
  tol = max(depth.profile, PD) * 0.1
  par(usr = c(u[1], u[2], min(depth.profile, PD) - tol, max(depth.profile, PD) + tol))
  time = c()
  depth = c()
  for(i in 1:length(depth.profile)){
    if(i == 1)
      time = c(time, axis.strata[i]+0.01, axis.strata[i+1])
    else
      time = c(time, axis.strata[i], axis.strata[i+1])
    depth = c(depth, depth.profile[i], depth.profile[i])
  }
  # plot proxy
  lines(time, depth, col = "gray35", lwd = 2)
  if(show.preferred.depth)
    lines(x = axis.strata, y = rep(PD, length(axis.strata)), col = "gray12", lwd = 2, lty = 3)
  if(show.axis){
    axis(1, col = 'grey35', at = axis.strata, labels = x.labs, lwd = 2, col.axis = 'grey35', cex.axis = .9)
    mtext(1, col = 'grey35', text=t.axis.lab , line = 1.5, cex = 1.2)
  }
  if(add.depth.axis){
    axis(2, col = 'grey35', labels = TRUE, lwd = 2, las = 2, col.axis = 'grey35', line = 0.5, cex.axis = .9)
    mtext(2, col = 'grey35', text="Sampling proxy", line = 2, cex = 1.2)
  }
}
