import { List } from 'immutable'
import React from 'react'

const FREEWHEEL_TICK = 60E3
const TITLES = {
	real_time: 'Time of Day',
	sun_map: 'Day/night map',
	sun_days: '"Days" since Unix Epoch',
	sun_hours: 'Hours of sun since start of Day'
}
const empty = List([
	['real_time', null],
	['sun_days', null],
	['sun_hours', null],
	['sun_map', null],
]);
const identity = a => a
const TOOLTIP_RENDER = {
	real_time: hours2time, // :${parseInt(((d * 60) % 1) * 60)}
	sun_map: v => ['Night', 'Day'][v],
	sun_days: identity,
	sun_hours: d => d.toFixed(2)
};

function hours2time(d) {
	return d < 0 ? '00:00' : `${zeropad(parseInt(d), 2)}:${zeropad(parseInt((d % 1) * 60), 2)}`
}
function latlon2xy(lat, lon) {
	return [(lon + 180) / 360, (-lat + 90) / 180];
}
function zeropad(s, n) {
	const x = Math.max(0, n - s.toString().length);
	return (x > 0 ? '0'.repeat(x) : '') + s.toString();
}
function bound(x, a, b) {
	return x < a ? a : (x > b ? b : x);
}
function tooltip([x, y], dat, f, cls) {
	const [w, h] = [dat.length, dat[0].length];
	const [a, b] = [bound(parseInt(w * x), 0, w-1), bound(parseInt(h * y), 0, h-1)];
	const d = dat[a][h-b-1];
	return [<React.Fragment>
		<div className={`tooltip-pixel-sel ${cls}`} style={{
			left: `${(a / w) * 100}%`,
			top: `${(b / h) * 100}%`,
			width: `${100 / w}%`,
			height: `${100 / h}%`
		}}></div>
		<div className={`tooltip-val ${cls}`} style={{
			left: `${(a / w) * 100}%`,
			top: `${((b + 1) / h) * 100}%`
		}}>{f === undefined ? d : f(d)}</div>
	</React.Fragment>, d];
}

export default class extends React.Component {
	constructor(props) {
		super(props);
		
		this.state = {
			time_tx: 0, time_rx: 0,
			place_tx: 0, place_rx: 0,
			j: empty,
			freewheeling: true,
			input_time: (new Date(Date.now())).toISOString(),
			input_place: '',
			place: null,
			pl_err: null,
			lu_err: null,
			mouse_xy: null
		};
	}
	componentDidMount() {
		this.handle_time_submit();
			
		setInterval(() => {
			if(this.state.freewheeling) {
				this.tick_now();
			}
		}, FREEWHEEL_TICK);
	}
	
	componentDidUpdate(prev_props, prev_state) {
		if(prev_state.lu_err !== this.state.lu_err && this.state.lu_err !== null) {
			setTimeout(_ => this.setState({ lu_err: null }), 7000);
		}
		if(prev_state.pl_err !== this.state.pl_err && this.state.pl_err !== null) {
			setTimeout(_ => this.setState({ pl_err: null }), 7000);
		}
	}
	
	tick_now = () => this.setState({
		input_time: (new Date(Date.now())).toISOString()
	}, this.handle_time_submit);
	
	handle_mousemove = e => {
		const bb = e.target.getBoundingClientRect();
		this.setState({
			mouse_xy: [
				(e.clientX - bb.left) / bb.width,
				(e.clientY - bb.top) / bb.height
			]
		});
	}
	
	handle_mouseleave = e => this.setState({ mouse_xy: null })
	
	handle_place_reset = e => this.setState({ input_place: '', place: null })
	
	handle_time_reset = e => this.setState({
		input_time: '',
		freewheeling: true
	}, this.tick_now)
	
	handle_time_submit = e => {
		if(e !== undefined) {
			e.stopPropagation();
			e.preventDefault();
		}
		
		const F = new FormData();
		F.set('dt', this.state.input_time); // , mode: 'cors'
		return fetch('/lu', { method: 'POST', body: F }).then(r => r.json())
			.then(j => j.err ? this.setState({ lu_err: j.err }) : this.setState(s => ({
				time_rx: s.time_rx + 1,
				j: List(j)
			})));
	}
	handle_place_submit = e => {
		if(e !== undefined) {
			e.stopPropagation();
			e.preventDefault();
		}
		
		const F = new FormData();
		F.set('q', this.state.input_place); // , mode: 'cors'
		return fetch('/pl', { method: 'POST', body: F }).then(r => r.json())
			.then(j => j.err ? this.setState({ pl_err: j.err }) : this.setState(s => ({
				place_rx: s.place_rx + 1,
				place: j
			})));
	}
		
	handle_input_time_focus = e => this.setState({
		freewheeling: false
	})
	handle_input_time = e => this.setState({
		input_time: e.target.value
	})
	handle_input_place = e => this.setState({
		input_place: e.target.value
	})
	render = () => <div id="rroot">
		<nav id="main_nav">
			<a href="https://lam.io" target="_blank"><div className="logo"></div></a>
			<ul className="flat-list">
				<li><a href="https://xkcd.com/2542/" target="_blank">XKCD 2542</a></li>
				<li><a href="https://lam.io/projects/x2542" target="_blank">How this works</a></li>
			</ul>
		</nav>
		<section id="input_container">
			<div className={`input-wrapper ${this.state.lu_err !== null ? 'err' : '' } ${this.state.freewheeling ? 'freewheeling' : ''}`}>
				<form action="/place" onSubmit={this.handle_time_submit}>
					<label htmlFor="input_time">Time</label>
					<div className="input-rewrapper">
						<input type="text" id="input_time" className="principal-input" placeholder="ISO-formatted time (yyyy-mm-ddThh:mm:ss)" onFocus={this.handle_input_time_focus} value={this.state.input_time} onChange={this.handle_input_time} />
						<input type="button" className="input-button" onClick={this.handle_time_reset} value="Clock mode" disabled={this.state.freewheeling} />
						<input type="submit" className="invisible" />
					</div>
					{ this.state.freewheeling && <div className="freewheel-msg">Clock mode on, updating every minute. Enter a time to disable.</div> }
					{ this.state.lu_err && <div className="err-msg">{this.state.lu_err}</div> }
				</form>
			</div>
			<div className={`input-wrapper ${this.state.pl_err !== null ? 'err' : '' }`}>
				<form action="/place" onSubmit={this.handle_place_submit}>
					<label htmlFor="input_place">Place</label>
					<div className="input-rewrapper">
						<input type="text" id="input_place" className="principal-input" placeholder="City name (e.g. Toronto)" value={this.state.input_place} onChange={this.handle_input_place} />
						<input type="button" className="input-button" onClick={this.handle_place_reset} value="Clear" />
						<input type="submit" className="invisible" />
					</div>
					{ this.state.pl_err && <div className="err-msg">{this.state.pl_err}</div> }
					{ this.state.place && (() => {
							const xy = latlon2xy(this.state.place.lat, this.state.place.lon);
							const [d, t] = ['sun_days', 'real_time'].map(a => tooltip(xy, this.state.j.filter(([k, _]) => k === a).get(0)[1][0])[1]);
							return <div className="place-time">
								<h3>Date & Time in {this.state.place.name}, {this.state.place.pcode}:</h3>
								<div>{(new Date(d * 86400 * 1E3)).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} {hours2time(t)}</div>
							</div>
						})()
					}
				</form>
			</div>
		</section>
		<section id="maps_container">
			{
				this.state.j.map(([k, l]) => {
					const loaded = this.state.time_rx > 0;
					const [dat, [im_dat, im_cbar]] = l || [null, [null, null]]; // eck. but it's good UX to see the maps load first so show it's working.
					
					return <figure className="map-fig">
						<h2>{TITLES[k]}</h2>
						<div className="fig-wrapper" key={k}>
							<div className="map-container">
								<div className="map-wrapper" onMouseMove={this.handle_mousemove} onMouseLeave={this.handle_mouseleave}>
									<div className="equimapper basemap" />
									<div className="equimapper map-overlay" style={{
										backgroundImage: `url(data:image/png;base64,${im_dat})`
									}} />
									{ loaded && this.state.place && tooltip(latlon2xy(this.state.place.lat, this.state.place.lon), dat, TOOLTIP_RENDER[k], 'place-tooltip')[0] }
									{ loaded && this.state.mouse_xy && tooltip(this.state.mouse_xy, dat, TOOLTIP_RENDER[k])[0] }
								</div>
							</div>
							<div className="cbar" style={{
								backgroundImage: loaded && `url(data:image/png;base64,${im_cbar})`
							}}></div>
						</div>
					</figure>;
				}).groupBy((_v, k) => parseInt(k / 2)).map(v =>
					<div className="fig-row">{v}</div>
				).toList().toArray()
			}
		</section>
	</div>
}