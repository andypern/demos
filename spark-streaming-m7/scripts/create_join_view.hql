create view USERNAME_pumpview as
select s.date, s.hz, s.disp, s.flo, s.sedPPM, s.psi, s.chlPPM, 
p.resourceid, p.type, p.purchasedate, p.dateinservice, p.vendor, p.longitude, p.latitude
from USERNAME_sensor s
join USERNAME_pump_info p
on (s.resid = p.resourceid);
