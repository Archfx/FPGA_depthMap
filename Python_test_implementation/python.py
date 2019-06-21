for m in range(0,5):
    for n in range(0,5):
        x=m-2
        y=n-2
        #print("+(org_L[(row +",x,") * WIDTH + col +",y,"  ]-org_R[(row +",x,") * WIDTH + col +",y,"-offset])*(org_L[(row + ",x,") * WIDTH + col +",y,"  ]-org_R[(row + ",x,") * WIDTH + col +",y,"-offset])")
        print("+(org_L[(row +",x,") * WIDTH + col +",y," + 1 ]-org_R[(row +",x,") * WIDTH + col +",y," - offset + 1 ])*(org_L[(row + ",x,") * WIDTH + col +",y," + 1  ]-org_R[(row + ",x,") * WIDTH + col +",y," - offset + 1])")


#ssd_1<=ssd_1+(org_L[(WIDTH+x) * row + col+y +1 ]-org_R[(WIDTH+x) * row + col+y-offset+1])*(org_L[(WIDTH+x) * row + col+y  +1]-org_R[(WIDTH+x) * row + col+y-offset+1]);
