import psycopg2 as pg
import datetime as dt
import dateutil
import math
import numpy as np
import psycopg2 as pg
import psycopg2.extras as pg_extras
from psycopg2.extensions import adapt, register_adapter, AsIs
import matplotlib as mpl
from matplotlib.figure import Figure
from matplotlib.colors import LogNorm
from flask import Flask, request
import io
import re
import json
import base64
import pytz

from .creds import creds

app = Flask(__name__)

# thanks https://stackoverflow.com/a/48391873/3925507

mpl.rcParams.update({
	"lines.color": "white",
	"patch.edgecolor": "white",
	"text.color": "black",
	"axes.facecolor": "white",
	"axes.edgecolor": "lightgray",
	"axes.labelcolor": "white",
	"xtick.color": "white",
	"ytick.color": "white",
	"grid.color": "lightgray"
})
	
def pcolor2b64(x, y, d, size=(1, 1), dpi=80, **kwargs):
	# thanks to https://stackoverflow.com/a/9295367/3925507
	fig = Figure()
	fig.set_size_inches(size)
	ax = fig.add_axes([0., 0., 1., 1.])
	ax.set_axis_off()
	c = ax.pcolor(x, y, d, **kwargs)
	
	im_bytes = io.BytesIO()
	fig.savefig(im_bytes, dpi=dpi, format='png', transparent=True)
	im_bytes.seek(0)
	
	cbar_bytes = io.BytesIO()
	cbar_fig = Figure(figsize=(0.4,4))
	ax = cbar_fig.add_axes([0, 0, 1, 1])
	cbar_fig.colorbar(c, cax=ax)
	cbar_fig.savefig(cbar_bytes, dpi=128, format='png', bbox_inches='tight', transparent=True)
	cbar_bytes.seek(0)
	
	return [str(base64.b64encode(b.read()), 'utf-8') for b in [im_bytes, cbar_bytes]]

def norm(D, **kwargs):
	return (D - np.min(D, **kwargs)) / (np.max(D, **kwargs) - np.min(D, **kwargs))

def chunk(cur, t, loc_id = None):
    cur.execute('''SELECT st0.*, udb.base AS last_tick
      FROM (
        SELECT l.id AS loc_id, l.lat, l.lng, s.rise, s.falls, s.unix_cumsum,
               LOWER(s.unix_cumsum) + GREATEST(%s::timestamp - s.rise, '0'::interval) AS sun_time
          FROM suns s
          INNER JOIN locs l ON s.loc_id = l.id
          WHERE s.falls @> %s::timestamp
              AND ((s.loc_id = %s) OR %s)
          ORDER BY l.lat ASC
      ) st0
      LEFT JOIN unix_day_bases udb ON st0.loc_id = udb.loc_id AND sun_day(st0.sun_time) = udb.sun_day;''', (t.isoformat(), t.isoformat(), int(loc_id) if loc_id != None else None, loc_id == None))
    return cur.fetchall()

@app.route('/pl', methods=['POST'])
def parse_place():
	with pg.connect('dbname=x2780 ' + creds) as conn:
		cur = conn.cursor(cursor_factory=pg_extras.RealDictCursor)
		
		try:
			place_raw = request.form['q']
		except KeyError:
			return { 'err': 'Query is missing.' }
		
		place = [p.strip() for p in re.split(r'\s*,\s*', place_raw)]
		cur.execute('''
			SELECT p.lat, p.lon, p.name, p.country_code AS pcode, c.code AS ccode FROM places p
				INNER JOIN names n ON p.geonameid = n.geonameid
				LEFT JOIN countries c ON c.code = p.country_code
				WHERE n.upper_name=%s AND ((UPPER(c.name)=%s) OR %s)
				ORDER BY name_rank DESC
		''', (place[0].upper(), place[-1].upper(), len(place) <= 1))
		cs = cur.fetchall()
		cs_countries = [c for c in cs if c['ccode'] != None]
		try:
			return cs_countries[0] if len(cs_countries) > 0 else cs[0]
		except Exception:
			return { 'err': '"%s" was not found.' % place_raw }

@app.route('/lu', methods=['POST', 'GET'])
def lu():
	with pg.connect('dbname=x2542 ' + creds) as conn:
		cur = conn.cursor(cursor_factory=pg_extras.RealDictCursor)
		body = request.form.to_dict()
		
		now = dt.datetime.now(tz=pytz.utc)
		if 'dt' in body and body['dt'] != '':
			try:
				now = dateutil.parser.parse(body['dt'])
			except ValueError:
				return { 'err': 'Use ISO8601 date/time: yyyy-mm-dd[Thh:mm:ss[±hh[:mm]]]' }
		
		if now.tzinfo is None or now.tzinfo.utcoffset(now) is None:
			now = now.astimezone(pytz.utc)
			
		if now < dt.datetime(1970, 1, 3, tzinfo=pytz.utc) or now > dt.datetime(2029, 12, 31, tzinfo=pytz.utc):
			return { 'err': 'Date is out of range. Data exists for years 1970-2030.' }
		
		unix_real_hours = []
		unix_sun_days = []
		unix_sun_hours = []

		lons = np.linspace(-180, 180, 32)
		hr_lons = (lons / 180 * 12 * 3600E6).astype('timedelta64[us]') # hours of longitude
		now_lons = np.datetime64(now) + hr_lons

		cur.execute('SELECT lat FROM locs ORDER BY id ASC;')
		lats = [a['lat'] for a in cur.fetchall()]

		day_len = np.timedelta64(12, 'h')
		# d0 = np.timedelta64()
		D = np.array([
		    [[
		        (now_lon - np.datetime64(c['last_tick'])), # real time
		        *np.divmod(np.timedelta64(c['sun_time']), day_len), # sun time
		        ((now_lon > np.datetime64(c['rise'])) & (now_lon < np.datetime64(c['falls'].upper))), # sunrise/sunset map
		    ] for c in chunk(cur, now_lon.item())]
		for now_lon in now_lons], dtype=np.object)
		
		fields = ['real_time', 'sun_days', 'sun_hours', 'sun_map']
		tys = [np.timedelta64, np.float, np.timedelta64, np.float]
		rescales = [1/3600E6, 1, 1/3600E6, 1]
		norms = [LogNorm(), None, None, None]
		X, Y = np.meshgrid(lons, lats)
		
		Ds = [D[:,:,i].astype(ty).astype(np.float) * rescale for i, (rescale, ty) in enumerate(zip(rescales, tys))]
		
		return json.dumps([
			(field, (
				D_.tolist(),
				pcolor2b64(X, Y, D_.T, size=((lons[-1]-lons[0])/128, (lats[-1]-lats[0])/128), dpi=128, norm=norm, shading='nearest'),
			)) for field, norm, D_ in zip(fields, norms, Ds)
		])