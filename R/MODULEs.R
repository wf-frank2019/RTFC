#' Identify robust modules from a certain network
#'
#' @title MODULEs function
#' @param edges data.frame, two columns:interactorA,interactorB(for example 'PPI').
#' @param heatmap Default TRUE,heatmap of modules difference will not plot if heatmap=FALSE.
#' @param tarGet Default TRUE,module drug target statistics will not Implement if tarGet=FALSE.
#' @import igraph ggplot2 reshape2
#' @export MODULEs
#' @author Fan Wang

MODULEs <- function(edges,
                    heatmap=TRUE,
                    tarGet=TRUE) {
  #check the format of parameters
  if(!class(edges) == "data.frame")
  {
    stop("Param 'edges' input error!
         Please input the dataframe!")
  }
  else if(ncol(edges) <2)
  {
    stop("Param 'edges' input error!
         Please input dataframe with two columns!
         for example: TP53,EGFR
                      TP53,KRAS
                      EGFR,KRAS")
  }
  time1<-Sys.time()
  w=f=0
  options(warn=-1)
  #Create the network
  g_fan = graph_from_data_frame(edges, directed=FALSE)
  #Objects clustering in different directions
  Ncount<-length(get.vertex.attribute(g_fan)[[1]])
  fan_GN<-cluster_edge_betweenness(g_fan,weights=NULL)
  fan_LP<-cluster_louvain(g_fan,weights=NULL)
  fan_GN_label=matrix(nrow = Ncount, ncol = 2)
  fan_GN_label<-as.data.frame(fan_GN_label)
  fan_GN_label[,1]=get.vertex.attribute(g_fan)[[1]]
  fan_GN_label[,2]=fan_GN$membership
  fan_LP_label=matrix(nrow = Ncount, ncol = 2)
  fan_LP_label<-as.data.frame(fan_LP_label)
  fan_LP_label[,1]=get.vertex.attribute(g_fan)[[1]]
  fan_LP_label[,2]=fan_LP$membership
  fan_GN_label_list <- list()
  #Extract objects in different clusters
  for(i in 1:length(fan_GN)){
    fan_GN_label_list[[i]]<-fan_GN_label[fan_GN_label$V2==i,1]
  }
  fan_LP_label_list <- list()
  for(i in 1:length(fan_LP)){
    fan_LP_label_list[[i]]<-fan_LP_label[fan_LP_label$V2==i,1]
  }
  #Remove outliers that belong to no cluster
  fan_GN_label_list2<- list()
  fan_GN_label_list2<-fan_GN_label_list[(lengths(fan_GN_label_list) >1)]
  fan_LP_label_list2<- list()
  fan_LP_label_list2<-fan_LP_label_list[(lengths(fan_LP_label_list) >1)]
  fan_GN_LP2<-as.data.frame(matrix(nrow=length(fan_LP_label_list2),
                                   ncol=length(fan_GN_label_list2)))
  fan_GN_LP_union2=fan_GN_LP2
  fan_GN_LP_phyper2=fan_GN_LP2
  #Hypergeometric test between each cluster pairs
  for(i in 1:length(fan_GN_label_list2)){
    for(j in 1:length(fan_LP_label_list2)){
      fan_GN_LP2[j,i]=length(intersect(fan_GN_label_list2[[i]],
                                       fan_LP_label_list2[[j]]))
      fan_GN_LP_union2[j,i]=length(union(fan_GN_label_list2[[i]],
                                         fan_LP_label_list2[[j]]))
    }
  }
  for(i in 1:ncol(fan_GN_LP_phyper2)){
    for(j in 1:nrow(fan_GN_LP_phyper2)){
      fan_GN_LP_phyper2[j,i]=1-phyper(fan_GN_LP2[j,i],
      length(fan_GN_label_list2[[i]]),fan_GN_LP_union2[j,i],
      length(fan_LP_label_list2[[j]]))
    }
  }
  colnames(fan_GN_LP_phyper2)<-paste("GN",
    seq(from=1,to=length(fan_GN_label_list2),by=1),sep="_")
  rownames(fan_GN_LP_phyper2)<-paste("LP",
    seq(from=1,to=length(fan_LP_label_list2),by=1),sep="_")
  #Correlation heat map between clusters
  cormat=as.data.frame(t(fan_GN_LP_phyper2))
  cormat$ID <-  row.names(cormat)
  fanplot <- melt(cormat, id.vars=c("ID"))
  p_fan <- ggplot(fanplot, aes(y=variable,x=ID))+
                  geom_tile(aes(fill=value))+
                  scale_fill_gradient(low = "red", high = "skyblue") +
                  labs(x='GN',y='LPA',title='Module Difference Significance')+
                  theme(plot.title = element_text(hjust = 0.5),
                        axis.text.x = element_text(angle = 45))
  #Extract significantly correlated clusters
  sig_fan=as.data.frame(which(fan_GN_LP_phyper2<0.05, arr.ind = TRUE))
  sig_fan_list<- list()
  for(i in 1:nrow(sig_fan)){
    sig_fan_list[[i]]<-intersect(fan_GN_label_list2[[sig_fan[i,2]]],
                                 fan_LP_label_list2[[sig_fan[i,1]]])
  }
  #Get module label of each object
  for(i in 1:length(sig_fan_list))
  {
    w=w+length(sig_fan_list[[i]])
  }
  modules=as.data.frame(matrix(nc=2,nr=w))
  for(i in 1:length(sig_fan_list))
  {
    w=f+1
    f=f+length(sig_fan_list[[i]])
    modules[w:f,1]<- unlist(sig_fan_list[[i]])
    modules[w:f,2]<- i
  }
  edges=edges[,1:2]
  edges$module=0
  #Get module label of each interaction
  for(i in 1:length(sig_fan_list))
     for(j in 1:nrow(edges))
  {
    pattern<-as.vector(modules[which(modules[,2]==i),1])
    if((edges[j,1] %in% pattern) &
       (edges[j,2] %in% pattern))
      edges$module[j] = i
  }
  patternM<-edges[!edges$module==0,]
  #Export module label of each object
  write.table(modules,"node_Module.txt",sep="\t",quote=F,row.names=F,
              col.names=c("name","module"))
  #Export module label of interactions
  write.table(patternM,"edge_Module.txt",sep="\t",quote=F,row.names=F,
              col.names=c("name1","name2","module"))
  if(tarGet){
    TTD_tarInfor=as.data.frame(readLines(
    'http://db.idrblab.net/ttd/sites/default/files/ttd_database/P1-01-TTD_target_download.txt'))
    tarM=as.data.frame(matrix(nc=3,nr=length(sig_fan_list)))
    tarM[,1]=1:length(sig_fan_list)
    tarmodules=modules
    tarmodules$tars=0
    for(i in 1:nrow(modules))
    {
      if(any(grep(paste(modules[i,1],"_HUMAN",sep=''),TTD_tarInfor[,1]))) tarmodules$tars[i]=1
    }
    for(i in 1:nrow(tarM))
    {
      tarM[i,2]<-sum(tarmodules[which(tarmodules[,2]==i),3])
      tarM[i,3]<-tarM[i,2]/(length(modules[which(modules[,2]==i),1]))
    }
    write.table(tarM,"Modules_druGable.txt",sep="\t",quote=F,row.names=F,
                col.names=c("Module","Targets_Count","Targets_Proportion"))
  }
  time2<-Sys.time()
  message("", appendLF = T)
  message(paste(c("MODULEs start at ", as.character(time1)), collapse = ""), appendLF = T)
  message(paste(c("MODULEs finish at ", as.character(time2)), collapse = ""), appendLF = T)
  message("", appendLF = T)
  if(heatmap){
    #ggsave(p_fan,filename = "***.pdf")
    return(p_fan)
  }
}
