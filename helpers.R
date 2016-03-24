library(matrixcalc)
load("data/mnist_9dim_6000_RtSNE_10000.Rds")
attach(new.dat)

# for MNIST data:
row2image <- function(line) {
  im <- matrix(as.numeric(line), 28, 28, byrow = TRUE)
  # return:
  im[28:1,]
}

# digit display function (set):
show.digits <- function(v){
  
  size <- min(99, length(v))
  set <- sample(v, size)
  digits <- new.dat[set, 3:786]
  nrow <- ceiling(size/10)
  im <- matrix(0, nrow=28*nrow, ncol=280)
  for(i in 1:nrow){ 
    ncol <- if(i==nrow) size %% 10 else 10
    for(j in 1:ncol){ 
      s <- row2image(digits[10*(i-1) + j,])
      im <- set.submatrix(im, s, 28*(i-1)+1, 28*(j-1)+1)
    }
  }
  par(mai=c(0,0,0,0))
  image( t(im),
         col=gray((256:0)/256), 
         zlim=c(0,1), xlab="", ylab="", asp=nrow/10,
         axes=FALSE
  )
  box(col='blue')
}

# digit display function (single):
show.digit <- function(idx){
  
  digit <- new.dat[idx, 3:786]
  im <- row2image(digit)
  par(mai=c(0,0,0,0))
  image( t(im),
         col=gray((256:0)/256), 
         zlim=c(0,1), xlab="", ylab="", asp=1,
         axes=FALSE
  )
}
