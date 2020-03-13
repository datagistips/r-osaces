## FONCTION DE SCALING DATA ####
# http://qgis.org/api/qgsexpression_8cpp_source.html#l00575
scaleData <- function(val, domainMin, domainMax, rangeMin, rangeMax, exponent=2, method="linear") {
  if (method == "linear") {
    m <- ( rangeMax - rangeMin ) / ( domainMax - domainMin )
    d <- m * (val - domainMin) + rangeMin
  } else {
    d <- (((rangeMax - rangeMin) / (domainMax - domainMin)^exponent ) * ( val - domainMin)^exponent + rangeMin) ;
  }
  return(d)
}

## FONCTION DE RADARS ####
radars <- function(f, dat, libelles, fact=.7, mult=.9, exponent=2, minFactor=1/6, method="linear") {
  
  ## CIRCLES
  ncircles <- nrow(f)
  
  meanArea <- mean(gArea(f, byid=T))
  radii <- sqrt((fact*meanArea)/pi)
  
  xyr <- data.frame(
    x = coordinates(f)[,1],
    y = coordinates(f)[,2],
    r = radii)
  # 
  res <- circleLayout(xyr, bbox(f)[1,], bbox(f)[2,], maxiter = 1000)
  cat(res$niter, "iterations performed")
  
  circles <- gBuffer(SpatialPoints(res$layout[, 1:2]), width=res$layout[,3], quadsegs=50, byid=T)
  circles.df <- SpatialPolygonsDataFrame(circles, data=data.frame(id=1:length(circles),
                                                                  libelle=libelles,
                                                                  row.names=row.names(circles)))
  # INI
  nTetes <- ncol(dat)
  inc <- 2*pi/nTetes
  ang0 <- pi/2
  
  ## RADARS
  j <- 1
  out <- vector(mode="list")
  for (idCircle in 1:nrow(res$layout)) {
    
    if (!all(is.na(dat[idCircle, ]))) {
      
      start <- as.matrix(res$layout[idCircle, 1:2])
      radius <- res$layout[idCircle, 3]
      
      domainMin <- min(dat[idCircle,])
      domainMax <- max(dat[idCircle,])
      
      for (i in 1:nTetes) {
        offsetAngle <- (i-1)*inc
        
        angs <- seq(ang0+offsetAngle,
                    ang0+inc+offsetAngle, length.out=10)
        
        rangeMin <- radius*minFactor
        rangeMax <- radius
        
        # exponent = 2
        # mult = .9
        val <- dat[idCircle, i]
        
        if(val > 0) {
          
          if (domainMin == domainMax) {
            d <- rangeMin
          } else {
            d <- mult * scaleData(val, domainMin, domainMax, rangeMin, rangeMax, exponent, method=method)
            print(d > rangeMax)
          }
          
          pts <- cbind((start[1] + d*cos(angs)),
                       (start[2] + d*sin(angs)))
          
          SpP <- SpatialPolygonsDataFrame(SpatialPolygons(list(Polygons(list(Polygon(rbind(start, pts, start))),
                                                                        paste(idCircle, i)))),
                                          dat=data.frame(libelle=libelles[idCircle],
                                                         idCategorie=i,
                                                         categorie=names(dat)[i],
                                                         value=val,
                                                         row.names=paste(idCircle, i)))
          out[[j]] <- SpP
          j <- j+1
          print(j)
        }
      }
    }
  }
  
  rosaces <- do.call(rbind, out)
  
  return(list(cercles=circles.df, rosaces=rosaces))
  
}