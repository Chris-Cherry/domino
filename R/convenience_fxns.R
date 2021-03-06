#' Renames clusters in a domino object
#' 
#' This function reads in a receptor ligand signaling database, cell level 
#' features of some kind (ie. output from pySCENIC), z-scored single cell data, 
#' and cluster id for single cell data, calculates a correlation matrix between 
#' receptors and other features (this is transcription factor module scores if 
#' using pySCENIC), and finds features enriched by cluster. It will return a 
#' domino object prepared for build_domino, which will calculate a signaling 
#' network.
#' 
#' @param dom A domino object to rename clusters in
#' @param clust_conv A named vector of conversions from old to new clusters. Values are taken as new clusters IDs and names as old cluster IDs.
#' @return A domino object with clusters renamed in all applicable slots.
#' @export 
#' 
rename_clusters = function(dom, clust_conv){
    if(is.null(clusters)){
        stop("There are no clusters in this domino object")
    }
    if(dom@misc$create){
        dom@clusters = plyr::revalue(dom@clusters, clust_conv)
        colnames(dom@clust_de) = clust_conv
        names(colnames(dom@clust_de)) = c()
    }
    if(dom@misc$build){
        names(dom@linkages$clust_tf) = clust_conv
        colnames(dom@signaling) = paste0('L_', clust_conv)
        rownames(dom@signaling) = paste0('R_', clust_conv)
        names(dom@cl_signaling_matrices) = clust_conv
        for(cl in clust_conv){
            colnames(dom@cl_signaling_matrices[[cl]]) = paste0('L_', clust_conv)
        }
    }
    return(dom)
}

#' Extracts all features, receptors, or ligands present in a signaling network.
#' 
#' This function collates all of the features, receptors, or ligands found in a
#' signaling network anywhere in a list of clusters. This can be useful for
#' comparing signaling networks across two separate conditions. In order to run
#' this build_domino must be run on the object previously.
#' 
#' @param dom A domino object containing a signaling network (i.e. build_domino run)
#' @param return A string indicating where to collate 'features', 'receptors', or 'ligands'. If 'all' then a list of all three will be returned.
#' @param clusters A vector indicating clusters to collate network items from. If left as NULL then all clusters will be included.
#' @return A vector containing all features, receptors, or ligands in the data set or a list containing all three.
#' @export 
#' 
collate_network_items = function(dom, clusters = NULL, return = NULL){
    if(!dom@misc[['build']]){
        stop('Please run domino_build prior to generate signaling network.')
    }
    if(is.null(clusters) & is.null(dom@clusters)){
        stop("There are no clusters in this domino object. Please provide clusters.")
    }
    if(is.null(clusters)){clusters = levels(dom@clusters)}

    # Get all TFs across specified clusters
    de_tfs = c()
    for(cl in clusters){
        tfs = dom@linkages$clust_tf[[cl]]
        de_tfs = c(de_tfs, tfs)
    }

    # Get connections between TF and recs
    all_recs = c()
    all_tfs = c()
    for(tf in de_tfs){
        recs = dom@linkages$tf_rec[[tf]]
        all_recs = c(all_recs, recs)
        if(length(recs)){
            all_tfs = c(all_tfs, tf)
        }
    }
    all_recs = unique(all_recs)
    all_tfs = unique(all_tfs)

    # Between ligs and recs
    all_ligs = c()
    for(rec in all_recs){
        ligs = dom@linkages$rec_lig[[rec]]
        mid = match(ligs, rownames(dom@z_scores))
        if(anyNA(mid)){
            ligs = ligs[-which(is.na(mid))]
        }
        all_ligs = c(all_ligs, ligs)
    }
    all_ligs = unique(all_ligs)

    # Make list and return whats asked for
    list_out = list('features' = all_tfs, 'receptors' = all_recs, 
        'ligands' = all_ligs)
    if(is.null(return)){
        return(list_out)
    } else {
        return(list_out[[return]])
    }
}