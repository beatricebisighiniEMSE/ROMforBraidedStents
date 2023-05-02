function write_vtk(filename, pos, u, conn)
    
    u = reshape(u', 3, int64(size(u, 1)/3));
    u = u';

    pos = pos + u;

    filename=sprintf(filename);
    fid = fopen(filename,'w+');
    fprintf(fid,'%s\n','# vtk DataFile Version 3.0');
    fprintf(fid,'%s\n','vtk output');
    fprintf(fid,'%s\n','ASCII');
    fprintf(fid,'%s\n','DATASET POLYDATA');
    
    fprintf(fid,'POINTS %d float\n',length(pos));
    for i=1:length(pos)
        fprintf( fid, '%f %f %f\n', pos(i,:));
    end
    
    nelem = size(conn,1);
    nnodes_line = size(conn,2);
    fprintf(fid,'LINES %d %d\n',nelem,nelem*(nnodes_line+1));
    for i=1:nelem
       fprintf(fid,'%d\n',nnodes_line);
       fprintf(fid,'%d\n',conn(i,1)-1);
       fprintf(fid,'%d\n',conn(i,2)-1);
    
    end
    
    fclose(fid);

end 
