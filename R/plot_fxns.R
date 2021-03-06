#' Create a network heatmap
#' 
#' Creates a heatmap of the signaling network. Alternatively, the network 
#' matrix can be accessed directly in the signaling slot of a domino object.
#' 
#' @param dom A domino object with network built (build_domino)
#' @param clusts A vector of clusters to be included. If NULL then all clusters are used.
#' @param min_thresh Minimum signaling threshold for plotting. Defaults to -Inf for no threshold.
#' @param max_thresh Maximum signaling threshold for plotting. Defaults to Inf for no threshold.
#' @param scale How to scale the values (after thresholding). Options are 'none', 'sqrt' for square root, or 'log' for log10.
#' @param normalize Options to normalize the matrix. Normalization is done after thresholding and scaling. Accepted inputs are 'none' for no normalization, 'rec_norm' to normalize to the maximum value with each receptor cluster, or 'lig_norm' to normalize to the maximum value within each ligand cluster 
#' @param ... Other parameters to pass to NMF::aheatmap
#' @export
#' 
signaling_heatmap = function(dom, clusts = NULL, min_thresh = -Inf, max_thresh = Inf, 
    scale = 'none', normalize = 'none', ...){
    if(!dom@misc[['build']]){
        stop('Please run domino_build prior to generate signaling network.')
    }
    if(!length(dom@clusters)){
        stop("This domino object wasn't built with clusters so intercluster signaling cannot be generated.")
    }

    mat = dom@signaling
    if(!is.null(clusts)){
        mat = mat[paste0('R_', clusts), paste0('L_', clusts)]
    }
    
    mat[which(mat > max_thresh)] = max_thresh
    mat[which(mat < min_thresh)] = min_thresh

    if(scale == 'sqrt'){
        mat = sqrt(mat)
    } else if(scale == 'log'){
        mat = log10(mat)
    } else if (scale != 'none'){
        stop('Do not recognize scale input')
    }
    

    if(normalize == 'rec_norm'){
        mat = do_norm(mat, 'row')
    } else if(normalize == 'lig_norm'){
        mat = do_norm(mat, 'col')
    } else if(normalize != 'none'){
        stop('Do not recognize normalize input')
    }
    NMF::aheatmap(mat, ...)
}

#' Create a cluster incoming signaling heatmap
#' 
#' Creates a heatmap of a cluster incoming signaling matrix. Each cluster has a
#' list of ligands capable of activating its enriched transcription factors. The
#' function creates a heatmap of cluster average expression for all of those 
#' ligands. A list of all cluster incoming signaling matrices can be found in
#' the cl_signaling_matrices slot of a domino option as an alternative to this
#' plotting function.
#' 
#' @param dom A domino object with network built (build_domino)
#' @param rec_clust Which cluster to select as the receptor. Must match naming of clusters in the domino object.
#' @param min_thresh Minimum signaling threshold for plotting. Defaults to -Inf for no threshold.
#' @param max_thresh Maximum signaling threshold for plotting. Defaults to Inf for no threshold.
#' @param scale How to scale the values (after thresholding). Options are 'none', 'sqrt' for square root, or 'log' for log10.
#' @param normalize Options to normalize the matrix. Accepted inputs are 'none' for no normalization, 'rec_norm' to normalize to the maximum value with each receptor cluster, or 'lig_norm' to normalize to the maximum value within each ligand cluster 
#' @param title Either a string to use as the title or a boolean describing whether to include a title. In order to pass the 'main' parameter to NMF::aheatmap you must set title to FALSE.
#' @param ... Other parameters to pass to NMF::aheatmap. Note that to use the 'main' parameter of NMF::aheatmap you must set title = FALSE
#' @export
#' 
incoming_signaling_heatmap = function(dom,  rec_clust, min_thresh = -Inf, 
    max_thresh = Inf, scale = 'none', normalize = 'none', title = TRUE, ...){
    if(!dom@misc[['build']]){
        stop('Please run domino_build prior to generate signaling network.')
    }
    if(!length(dom@clusters)){
        stop("This domino object wasn't build with clusters so cluster specific expression is not possible.")
    }
    mat = dom@cl_signaling_matrices[[rec_clust]]
    if(dim(mat)[1] == 0){
        print('No signaling found for this cluster under build parameters.')
        return()
    }
    mat[which(mat > max_thresh)] = max_thresh
    mat[which(mat < min_thresh)] = min_thresh

    if(scale == 'sqrt'){
        mat = sqrt(mat)
    } else if(scale == 'log'){
        mat = log10(mat)
    } else if (scale != 'none'){
        stop('Do not recognize scale input')
    }

    if(normalize == 'rec_norm'){
        mat = do_norm(mat, 'row')
    } else if(normalize == 'lig_norm'){
        mat = do_norm(mat, 'col')
    } else if(normalize != 'none'){
        stop('Do not recognize normalize input')
    }

    if(title == TRUE){
        NMF::aheatmap(mat, main = paste0('Expression of ligands targeting cluster ', rec_clust), ...)
    } else if(title == FALSE){
        NMF::aheatmap(mat, ...)
    } else {
        NMF::aheatmap(mat, main = title, ...)
    }
}

#' Create a cluster to cluster signaling network diagram
#' 
#' Creates a network diagram of signaling between clusters. Nodes are clusters
#' and directed edges indicate signaling from one cluster to another. Edges are
#' colored based on the color scheme of the ligand expressing cluster.
#' 
#' @param dom A domino object with network built (build_domino)
#' @param cols A named vector indicating the colors for clusters. Values are colors and names must match clusters in the domino object. If left as NULL then ggplot colors are generated for the clusters.
#' @param edge_weight Weight for determining thickness of edges on plot. Signaling values are multiplied by this value.
#' @param clusts A vector of clusters to be included in the network plot.
#' @param min_thresh Minimum signaling threshold. Values lower than the threshold will be set to the threshold. Defaults to -Inf for no threshold.
#' @param max_thresh Maximum signaling threshold for plotting. Values higher than the threshold will be set to the threshold. Defaults to Inf for no threshold.
#' @param normalize Options to normalize the signaling matrix. Accepted inputs are 'none' for no normalization, 'rec_norm' to normalize to the maximum value with each receptor cluster, or 'lig_norm' to normalize to the maximum value within each ligand cluster 
#' @param scale How to scale the values (after thresholding). Options are 'none', 'sqrt' for square root, 'log' for log10, or 'sq' for square.
#' @param layout Type of layout to use. Options are 'random', 'sphere', 'circle', 'fr' for Fruchterman-Reingold force directed layout, and 'kk' for Kamada Kawai for directed layout.  
#' @param scale_by How to size vertices. Options are 'lig_sig' for summed outgoing signaling, 'rec_sig' for summed incoming signaling, and 'none'. In the former two cases the values are scaled with asinh after summing all incoming or outgoing signaling.
#' @param vert_scale Integer used to scale size of vertices with our without variable scaling from size_verts_by.
#' @param ... Other parameters to be passed to plot when used with an igraph object.
#' @export
#' 
signaling_network = function(dom,  cols = NULL, edge_weight = .3, clusts = NULL, 
    min_thresh = -Inf, max_thresh = Inf, normalize = 'none', scale = 'sq', 
    layout = 'circle', scale_by = 'rec_sig', vert_scale = 3, ...){
    if(!length(dom@clusters)){
        stop("This domino object was not built with clusters so there is no intercluster signaling.")
    }
    if(!dom@misc[['build']]){
        stop('Please build a signaling network with domino_build prior to plotting.')
    }
    
    # Deal with nulls and get signaling matrix
    mat = dom@signaling
    if(!is.null(clusts)){
        mat = mat[paste0('R_', clusts), paste0('L_', clusts)]
    }
    
    if(is.null(cols)){
        cols = ggplot_col_gen(length(levels(dom@clusters)))
        names(cols) = levels(dom@clusters)
    }
    
    mat[which(mat > max_thresh)] = max_thresh
    mat[which(mat < min_thresh)] = min_thresh

    if(scale == 'sqrt'){
        mat = sqrt(mat)
    } else if(scale == 'log'){
        mat = log10(mat)
    } else if (scale == 'sq'){
        mat = mat^2
    } else if (scale != 'none'){
        stop('Do not recognize scale input')
    }

    if(normalize == 'rec_norm'){
        mat = do_norm(mat, 'row')
    } else if(normalize == 'lig_norm'){
        mat = do_norm(mat, 'col')
    } else if(normalize != 'none'){
        stop('Do not recognize normalize input')
    }    

    links = c()
    weights = c()
    for(rcl in levels(dom@clusters)){
        for(lcl in levels(dom@clusters)){
            if(mat[paste0('R_', rcl), paste0('L_', lcl)] == 0){
                next
            }
            links = c(links, as.character(lcl), as.character(rcl))
            weights[paste0(lcl, '|', rcl)] = mat[paste0('R_', rcl), 
                paste0('L_', lcl)]
        }
    }

    graph = igraph::graph(links)
    
    # Get vert colors and scale size if desired.
    igraph::V(graph)$label.dist = 1.5
    igraph::V(graph)$label.color = 'black'

    if(is.null(cols)){
        cols = ggplot_col_gen(length(levels(dom@clusters)))
        names(cols) = levels(dom@clusters)
    }
    v_cols = rep('#BBBBBB', length(igraph::V(graph)))
    names(v_cols) = names(igraph::V(graph))
    v_cols[names(cols)] = cols

    if(scale_by == 'lig_sig'){
        vals = asinh(colSums(mat))
        vals = vals[paste0('L_', names(igraph::V(graph)))]
        igraph::V(graph)$size = vals*vert_scale
    } else if(scale_by == 'rec_sig'){
        vals = asinh(rowSums(mat))
        vals = vals[paste0('R_', names(igraph::V(graph)))]
        igraph::V(graph)$size = vals*vert_scale
    } else if(scale_by == 'none'){
        igraph::V(graph)$size = vert_scale
    } else {
        stop("Don't recognize vert_scale option as 'none', 'rec_sig', or 'lig_sig'")
    }
    
    # Get vert angle for labeling circos plot
    if(layout == 'circle'){
        v_angles = 1:length(igraph::V(graph))
        v_angles = -2*pi*(v_angles-1)/length(v_angles)
        igraph::V(graph)$label.degree = v_angles
    }


    names(v_cols) = c()
    igraph::V(graph)$color = v_cols

    # Get edge color. weights, and lines
    weights = weights[attr(igraph::E(graph), 'vnames')]
    e_cols = c()
    for(e in names(weights)){
        lcl = strsplit(e, '|', fixed = TRUE)[[1]][1]
        e_cols = c(e_cols, cols[lcl])
    }
    names(weights) = c()
    names(e_cols) = c()
    igraph::E(graph)$width = weights*edge_weight
    igraph::E(graph)$color = e_cols
    igraph::E(graph)$arrow.size = 0
    igraph::E(graph)$curved = 0.5
    # Get edge colors

    if(layout == 'random'){
        l = igraph::layout_randomly(graph)
    } else if(layout == 'circle'){
        l = igraph::layout_in_circle(graph)
    } else if(layout == 'sphere'){
        l = igraph::layout_on_sphere(graph)
    } else if(layout == 'fr'){
        l = igraph::layout_with_fr(graph)
    } else if(layout == 'kk'){
        l = igraph::layout_with_kk(graph)
    }
    
    plot(graph, layout = l, ...)
}

#' Creates a gene association network
#' 
#' Creates a gene association network for genes from a given cluster. The 
#' selected cluster acts as the receptor for the gene association network, so
#' only ligands, receptors, and features associated with the receptor cluster
#' will be included in the plot.
#' 
#' @param dom A domino object with network built (build_domino)
#' @param clust The receptor cluster to create the gene association network for. A vector of clusters may be provided.
#' @param class_cols A named vector of colors used to color classes of vertices. Values must be colors and names must be classes ('rec', 'lig', and 'feat' for receptors, ligands, and features.). 
#' @param cols A named vector of colors for individual genes. Genes not included in this vector will be colored according to class_cols.
#' @param lig_scale FALSE or a numeric value to scale the size of ligand vertices based on z-scored expression in the data set.
#' @param layout Type of layout to use. Options are 'grid', 'random', 'sphere', 'circle', 'fr' for Fruchterman-Reingold force directed layout, and 'kk' for Kamada Kawai for directed layout.
#' @param ... Other parameters to pass to plot() with an igraph object. See igraph manual for options.
#' @export
#' 
gene_network = function(dom, clust = NULL, class_cols = c(lig = '#FF685F', 
    rec = '#47a7ff', feat = '#39C740'), cols = NULL, lig_scale = 1, 
    layout = 'grid', ...){
    if(!dom@misc[['build']]){
        warning('Please build a signaling network with domino_build prior to plotting.')
    }
    if(!length(dom@clusters)){
        warning("This domino object wasn't build with clusters. The global signaling network will be shown.")
        lig_scale = FALSE
    }

    # Get connections between TF and recs for clusters
    if(length(dom@clusters)){
        all_sums = c()
        tfs = c()
        cl_with_signaling = c()
        for(cl in as.character(clust)){
            # Check if signaling exists for target cluster
            mat = dom@cl_signaling_matrices[[cl]]
            if(dim(mat)[1] == 0){
                print(paste('No signaling found for', cl, 'under build parameters.'))
                next()
            }
            all_sums = c(all_sums, rowSums(mat))
            tfs = c(tfs, dom@linkages$clust_tf[[cl]])
            cl_with_signaling = c(cl_with_signaling, cl)
        }
        all_sums = all_sums[-which(duplicated(names(all_sums)))]
    
        # If no signaling for target clusters then don't do anything
        if(length(tfs) == 0){
            print('No signaling found for provided clusters')
            return()
        }
    } else {
        tfs = dom@linkages$clust_tf[['clust']]
    }

    links = c()
    all_recs = c()
    all_tfs = c()
    for(tf in tfs){
        recs = dom@linkages$tf_rec[[tf]]
        all_recs = c(all_recs, recs)
        if(length(recs)){
            all_tfs = c(all_tfs, tf)
        }
        for(rec in recs){
            links = c(links, rec, tf)
        }
    }
    all_recs = unique(all_recs)
    all_tfs = unique(all_tfs)

    # Recs to ligs
    if(length(dom@clusters)){
        allowed_ligs = c()
        for(cl in cl_with_signaling){
            allowed_ligs = rownames(dom@cl_signaling_matrices[[cl]])
        }
    } else {
        allowed_ligs = rownames(dom@z_scores)
    }

    # Remove ligs not expressed in data set if desired
    all_ligs = c()
    for(rec in all_recs){
        ligs = dom@linkages$rec_lig[[rec]]
        for(lig in ligs){
            if(length(which(allowed_ligs == lig))){
                links = c(links, lig, rec)
                all_ligs = c(all_ligs, lig)
            }
        }
    }
    all_ligs = unique(all_ligs)

    # Make the graph
    graph = igraph::graph(links)
    graph = igraph::simplify(graph, remove.multiple = TRUE, remove.loops = FALSE)
    
    v_cols = rep('#BBBBBB', length(igraph::V(graph)))
    names(v_cols) = names(igraph::V(graph))
    v_cols[all_tfs] = class_cols['feat']
    v_cols[all_recs] = class_cols['rec']
    v_cols[all_ligs] = class_cols['lig']
    if(!is.null(cols)){
        v_cols[names(cols)] = cols
    }
    names(v_cols) = c()
    igraph::V(graph)$color = v_cols


    v_size = rep(10, length(igraph::V(graph)))
    names(v_size) = names(igraph::V(graph))
    if(lig_scale){
        v_size[names(all_sums)] = 10*all_sums*lig_scale
    }
    names(v_size) = c()
    igraph::V(graph)$size = v_size
    igraph::V(graph)$label.degree = pi
    igraph::V(graph)$label.offset = 2
    igraph::V(graph)$label.color = 'black'
    igraph::V(graph)$frame.color = 'black'

    igraph::E(graph)$width = .5
    igraph::E(graph)$arrow.size = 0
    igraph::E(graph)$color = 'black'

    if(layout == 'grid'){
        l = matrix(0, ncol = 2, nrow = length(igraph::V(graph)))
        rownames(l) = names(igraph::V(graph))

        l[all_ligs,1] = -.75
        l[all_recs,1] = 0
        l[all_tfs,1] = .75

        l[all_ligs,2] = (1:length(all_ligs)/mean(1:length(all_ligs)) - 1)*2
        l[all_recs,2] = (1:length(all_recs)/mean(1:length(all_recs)) - 1)*2
        l[all_tfs,2] = (1:length(all_tfs)/mean(1:length(all_tfs)) - 1)*2
        
        rownames(l) = c()
    } else if(layout == 'random'){
        l = igraph::layout_randomly(graph)
    } else if(layout == 'circle'){
        l = igraph::layout_in_circle(graph)
    } else if(layout == 'sphere'){
        l = igraph::layout_on_sphere(graph)
    } else if(layout == 'fr'){
        l = igraph::layout_with_fr(graph)
    } else if(layout == 'kk'){
        l = igraph::layout_with_kk(graph)
    }
    
    plot(graph, layout = l, ...)
    return(invisible(list(graph = graph, layout = l)))
}

#' Create a heatmap of features organized by cluster
#' 
#' Creates a heatmap of feature expression (typically transcription factor
#' activation scores) by cells organized by cluster.
#' 
#' @param dom A domino object with network built (build_domino)
#' @param bool A boolean indicating whether the heatmap should be continuous or boolean. If boolean then bool_thresh will be used to determine how to define activity as positive or negative.
#' @param bool_thresh A numeric indicating the threshold separating 'on' or 'off' for feature activity if making a boolean heatmap.
#' @param title Either a string to use as the title or a boolean describing whether to include a title. In order to pass the 'main' parameter to NMF::aheatmap you must set title to FALSE.
#' @param norm Boolean indicating whether or not to normalize the transcrption factors to their max value.
#' @param feats Either a vector of features to include in the heatmap or 'all' for all features. If left NULL then the features selected for the signaling network will be shown.
#' @param ann_cols Boolean indicating whether to include cell cluster as a column annotation. Colors can be defined with cols. If FALSE then custom annotations can be passed to NMF.
#' @param cols A named vector of colors to annotate cells by cluster color. Values are taken as colors and names as cluster. If left as NULL then default ggplot colors will be generated.
#' @param min_thresh Minimum threshold for color scaling if not a boolean heatmap
#' @param max_thresh Maximum threshold for color scaling if not a boolean heatmap
#' @param ... Other parameters to pass to NMF::aheatmap. Note that to use the 'main' parameter of NMF::aheatmap you must set title = FALSE and to use 'annCol' or 'annColors' ann_cols must be FALSE.
#' @export
#' 
feat_heatmap = function(dom, feats = NULL, bool = TRUE, bool_thresh = .2, 
    title = TRUE, norm = FALSE, cols = NULL, ann_cols = TRUE, min_thresh = NULL, 
    max_thresh = NULL, ...){
    if(!length(dom@clusters)){
        warning("This domino object wasn't build with clusters. Cells will not be ordered.")
        ann_cols = FALSE
    }
    mat = dom@features
    cl = dom@clusters
    cl = sort(cl)

    if(norm & (!is.null(min_thresh) | !is.null(max_thresh))){
        warning('You are using norm with min_thresh and max_thresh. Note that values will be thresholded AFTER normalization.')
    }

    if(norm){
        mat = do_norm(mat, 'row')
    }

    if(!is.null(min_thresh)){
        mat[which(mat < min_thresh)] = min_thresh
    }
    if(!is.null(max_thresh)){
        mat[which(mat > max_thresh)] = max_thresh
    }

    if(bool){
        cp = mat
        cp[which(mat >= bool_thresh)] = 1
        cp[which(mat < bool_thresh)] = 0
        mat = cp
    }

    if(title == TRUE){
        title = 'Feature expression by cluster'
    }

    if(is.null(feats)){
        feats = c()
        links = dom@linkages$clust_tf
        for(i in links){
            feats = c(feats, i)
        }
        feats = unique(feats)
    } else if(feats[1] != 'all'){
        mid = match(feats, rownames(dom@features))
        na = which(is.na(mid))
        na_feats = paste(feats[na], collapse = ' ')
        if(length(na) != 0){
            print(paste('Unable to find', na_feats))
            feats = feats[-na]
        } 
    } else if(feats == 'all'){
        feats = rownames(mat)
    }

    if(length(cl)){
        mat = mat[feats, names(cl)]
    }
    
    if(ann_cols){
        ac = list('Cluster' = cl)
        names(ac[[1]]) = c()
        if(is.null(cols)){
            cols = ggplot_col_gen(length(levels(cl)))
            names(cols) = levels(cl)
        }
        cols = list('Cluster' = cols)
    }

    if(title != FALSE & ann_cols != FALSE){
        NMF::aheatmap(mat, Colv = NA, annCol = ac, annColors = cols, main = title, ...)
    } else if(title == FALSE & ann_cols != FALSE){
        NMF::aheatmap(mat, Colv = NA, annCol = ac, annColors = cols, ...)
    } else if(title != FALSE & ann_cols == FALSE){
        NMF::aheatmap(mat, Colv = NA, main = title, ...)
    } else if(title == FALSE & ann_cols == FALSE){
        NMF::aheatmap(mat, Colv = NA, ...)
    }
}

#' Create a heatmap of correlation between receptors and transcription factors
#' 
#' Creates a heatmap of correlation values between receptors and transcription 
#' factors.
#' 
#' @param dom A domino object with network built (build_domino)
#' @param bool A boolean indicating whether the heatmap should be continuous or boolean. If boolean then bool_thresh will be used to determine how to define activity as positive or negative.
#' @param bool_thresh A numeric indicating the threshold separating 'on' or 'off' for feature activity if making a boolean heatmap.
#' @param title Either a string to use as the title or a boolean describing whether to include a title. In order to pass the 'main' parameter to NMF::aheatmap you must set title to FALSE.
#' @param feats Either a vector of features to include in the heatmap or 'all' for all features. If left NULL then the features selected for the signaling network will be shown.
#' @param recs Either a vector of receptors to include in the heatmap or 'all' for all receptors. If left NULL then the receptors selected in the signaling network connected to the features plotted will be shown.
#' @param mark_connections A boolean indicating whether to add an 'x' in cells where there is a connected receptor or TF. Default FALSE.
#' @param ... Other parameters to pass to NMF::aheatmap. Note that to use the 'main' parameter of NMF::aheatmap you must set title = FALSE and to use 'annCol' or 'annColors' ann_cols must be FALSE.
#' @export
#' 
cor_heatmap = function(dom, bool = TRUE, bool_thresh = .15, title = TRUE, 
    feats = NULL, recs = NULL, mark_connections = FALSE, ...){
    mat = dom@cor

    if(bool){
        cp = mat
        cp[which(mat >= bool_thresh)] = 1
        cp[which(mat < bool_thresh)] = 0
        mat = cp
    }

    if(title == TRUE){
        title = 'Correlation of features and receptors'
    }

    if(is.null(feats)){
        feats = c()
        links = dom@linkages$clust_tf
        for(i in links){
            feats = c(feats, i)
        }
        feats = unique(feats)
    } else if(feats[1] != 'all'){
        mid = match(feats, rownames(dom@features))
        na = which(is.na(mid))
        na_feats = paste(feats[na], collapse = ' ')
        if(length(na) != 0){
            print(paste('Unable to find', na_feats))
            feats = feats[-na]
        } 
    } else if(feats == 'all'){
        feats = rownames(mat)
    }

    if(is.null(recs)){
        recs = c()
        links = dom@linkages$tf_rec
        for(feat in feats){
            feat_recs = links[[feat]]
            if(length(feat_recs) > 0){
                recs = c(recs, feat_recs)
            }
        }
        recs = unique(recs)
    } else if(recs == 'all'){
        recs = rownames(mat)
    }

    mat = mat[recs, feats]

    if(mark_connections){
        cons = mat
        cons[] = ''
        for(feat in feats){
            feat_recs = dom@linkages$tf_rec[[feat]]
            if(length(feat_recs)){
                cons[feat_recs, feat] = 'X'
            }
        }
    }

    if(title != FALSE & mark_connections){
        NMF::aheatmap(mat, main = title, txt = cons, ...)
    } else {
        NMF::aheatmap(mat, ...)
    }
}

#' Create a correlation plot between transcription factor activation score and receptor
#' 
#' Create a correlation plot between transcription factor activation score and receptor
#' 
#' @param dom A domino object with network built (build_domino)
#' @param tf Target TF module for plotting with receptor
#' @param rec Target receptor for plotting with TF
#' @param remove_rec_dropout Whether to remove cells with zero expression for plot. This should match the same setting as in build_domino.
#' @param ... Other parameters to pass to ggscatter.
#' @export
#' 
cor_scatter = function(dom, tf, rec, remove_rec_dropout = TRUE, ...){
    if(remove_rec_dropout){
        keep_id = which(dom@counts[rec,] > 0)
        rec_z_scores = dom@z_scores[rec, keep_id]
        tar_tf_scores = dom@features[tf, keep_id]
    } else {
        rec_z_scores = dom@z_scores[rec,]
        tar_tf_scores = dom@features[tf,]
    }

    dat = data.frame(rec = rec_z_scores, tf = tar_tf_scores)
    ggpubr::ggscatter(dat, x = "rec", y = "tf", 
          add = "reg.line", conf.int = FALSE, 
          cor.coef = FALSE, cor.method = "pearson",
          xlab = rec, ylab = tf, size = .25)

}

#' Normalize a matrix to its max value by row or column
#' 
#' Normalizes a matrix to its max value by row or column
#' 
#' @param mat The matrix to be normalized
#' @param dir The direction to normalize the matrix c('row', 'col') 
#' @return Normalized matrix in the direction specified.
do_norm = function(mat, dir){
    if(dir == 'row'){
        mat = t(apply(mat, 1, function(x){x/max(x)}))
        return(mat)
    } else if(dir == 'col'){
        mat = apply(mat, 2, function(x){x/max(x)})
        return(mat)
    }
}

#' Generate ggplot colors
#' 
#' Accepts a number of colors to generate and generates a ggplot color spectrum.
#' 
#' @param n Number of colors to generate
#' @return A vector of colors according to ggplot color generation.
#' 
ggplot_col_gen = function(n){
    hues = seq(15, 375, length = n + 1)
    return(hcl(h = hues, l = 65, c = 100)[1:n])
}
