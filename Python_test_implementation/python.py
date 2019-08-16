for m in range(0,5):
    for n in range(0,5):
        x=m-2
        y=n-2
        print("+(to_integer(unsigned(org_L((to_integer(unsigned(row)) +",x,") * WIDTH + to_integer(unsigned(col)) +",y,"  ))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +",x,") * WIDTH + to_integer(unsigned(col)) +",y,"- to_integer(unsigned(offset)))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) + ",x,") * WIDTH + to_integer(unsigned(col)) +",y,"  ))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + ",x,") * WIDTH + to_integer(unsigned(col)) +",y,"-to_integer(unsigned(offset)))))")
        #print("+(org_L[(row +",x,") * WIDTH + col +",y," + 1 ]-org_R[(row +",x,") * WIDTH + col +",y," - offset + 1 ])*(org_L[(row + ",x,") * WIDTH + col +",y," + 1  ]-org_R[(row + ",x,") * WIDTH + col +",y," - offset + 1])")


#ssd_1<=ssd_1+(org_L[(WIDTH+x) * row + col+y +1 ]-org_R[(WIDTH+x) * row + col+y-offset+1])*(org_L[(WIDTH+x) * row + col+y  +1]-org_R[(WIDTH+x) * row + col+y-offset+1]);
