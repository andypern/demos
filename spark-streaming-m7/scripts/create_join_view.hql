create view pumpview as
select s.date, s.hz, s.displace, s.flow, s.sedimentppm, s.pressurelbs, s.chlorineppm, 
p.resourceid, p.type, p.purchasedate, p.dateinservice, p.vendor, p.longitude, p.latitude
from sensor s
join pump_info p
on (s.resourceid = p.resourceid);
