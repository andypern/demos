create view USERNAME_SPARK_pumpview as
select s.date, s.hz, s.disp, s.flo, s.sedPPM, s.psi, s.chlPPM, 
p.resourceid, p.type, p.purchasedate, p.dateinservice, p.vendor, p.longitude, p.latitude
from USERNAME_SPARK_sensor s
join USERNAME_SPARK_pump_info p
on (s.resid = p.resourceid);
