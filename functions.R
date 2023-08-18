# update functions

update_u_p<-function(p,M,C,U,V,Q,lam,K){
  v_p<-V[p,,drop=F]
  sumC<-0; q_p<-0
  if(p<=K){
    q_p<-Q[p,,drop=F]
    sumC<-(C-t(U[1:K,][-p,])%*%Q[-p,])%*%t(q_p)
  }

  sumM<-(M-t(U[-p,])%*%V[-p,])%*%t(v_p)
  u_p<-t((sumM+lam*sumC)/(sum((v_p)^2) + lam*sum((q_p)^2)))
  #t(u_p)
  #t(v_p)
  u_p[u_p<0]<-0
  u_p<-u_p/sum(u_p)
  return(u_p)
}

update_u_p0<-function(p,M,U,V,K){
  v_p<-V[p,,drop=F]
  sumM<-(M-t(U[-p,])%*%V[-p,])%*%t(v_p)
  u_p<-t((sumM)/(sum((v_p)^2)))
  #t(u_p)
  #t(v_p)
  u_p[u_p<0]<-0
  u_p<-u_p/sum(u_p)
  return(u_p)
}

update_v_p<-function(p,M,U,V){
  u_p<-U[p,,drop=F]
  sumM<-u_p%*%(M-t(U[-p,])%*%V[-p,])
  v_p<-((sumM)/(sum((u_p)^2)))
  #t(u_p)
  #t(sumM)
  #t(v_p)
  v_p[v_p<0]<-0
  #v_p<-v_p/sum(v_p)
  return(v_p)
}

update_q_p<-function(p,C,U,Q){
  u_p<-U[p,,drop=F]
  sumC<-u_p%*%(C-t(U[-p,])%*%Q[-p,])
  q_p<-t((sumC)/(sum((u_p)^2)))
  q_p[q_p<0]<-0
  #q_p<-q_p/sum(q_p)
  return(q_p)
}

# main functions to compute projection with and without regularization

compute_proj0<-function(M,K,thr=10^(-5),seed=1,iters=100){
  set.seed(seed)
  conv<-F
  i=0
  #initMat<-irlba::svdr(M,k=K)
  #U<-t(initMat$u)
  U=matrix(runif(dim(M)[1]*K),K,dim(M)[1])
  V=solve((U)%*%t(U))%*%(U)%*%(M); V[V<0]<-0
  loss<-1000
  print(K)
  while(!conv){
    i<-i+1


    for(p in 1:K){
      U[p,]<-update_u_p0(p=p,M=M,U=U,V=V)
      V[p,]<-update_v_p(p=p,M=M,U=U,V=V)
    }


    #check convergence
    loss<-c(loss, sum((M-t(U)%*%V)^2)/sum(M^2))
    losses<-c(sum((M-t(U)%*%V)^2)/sum(M^2))
    crit<-1000
    if(i>3){
      crit<-loss[length(loss)]-loss[length(loss)-1]
    }

    if(crit<thr|i>iters){
      conv<-TRUE
    }
    #print(loss[length(loss)])
  }
  #ratio of proportions of the explained variance
  props<-c((1-sum((M-t(U)%*%V)^2)/sum((M)^2)))
  prop<-props[1]/1
  out<-list(V=V,U=U,lam=0,prop=prop,props=props,loss=loss,losses=losses,iters=i)

  return(out)
}

compute_proj<-function(M,C,K,#topics
                         lam,thr=10^(-5),seed=1,iters=100){
  set.seed(seed)
  conv<-F
  i=0
  #initMat<-irlba::svdr(M,k=K+Kt)
  #U<-t(initMat$u)
  U=matrix(runif(dim(M)[1]*(K)),(K),dim(M)[1])
  V=solve((U)%*%t(U))%*%(U)%*%(M); V[V<0]<-0
  Q=solve((U[1:K,])%*%t(U[1:K,]))%*%(U[1:K,])%*%(C); Q[Q<0]<-0
  loss<-1000
  print(K)
  while(!conv){
    i<-i+1


    for(p in 1:K){
      U[p,]<-update_u_p(p=p,M=M,C=C,U=U,V=V,Q=Q,lam=lam,K=K)
      V[p,]<-update_v_p(p=p,M=M,U=U,V=V)
      Q[p,]<-update_q_p(p=p,C=C,U=U[1:K,],Q=Q)
    }

    #check convergence
    loss<-c(loss, sum((M-t(U)%*%V)^2)/sum(M^2) + lam*sum((C-t(U[1:K,])%*%Q)^2)/sum(C^2))
    losses<-c(sum((M-t(U)%*%V)^2)/sum(M^2),sum((C-t(U[1:K,])%*%Q)^2)/sum(C^2))
    crit<-1000
    if(i>3){
      crit<-loss[length(loss)]-loss[length(loss)-1]
    }

    if(crit<thr|i>iters){
      conv<-TRUE
    }
    #print(loss[length(loss)])
  }
  #ratio of proportions of the explained variance
  props<-c((1-sum((M-t(U)%*%V)^2)/sum((M)^2)),(1-sum((C-t(U[1:K,])%*%Q)^2)/sum((C)^2)))
  prop<-props[1]/props[2]
  out<-list(V=V,U=U,Q=Q,lam=lam,prop=prop,props=props,loss=loss,losses=losses,iters=i)

  return(out)
}
