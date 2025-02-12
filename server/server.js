const Koa = require('koa');
const Router = require('koa-router');
const bodyParser = require('koa-bodyparser');
const WebSocket = require('koa-websocket');
const sqlite3 = require('sqlite3').verbose();

const app = new WebSocket(new Koa());
const router = new Router();

const clients = new Set();

const db = new sqlite3.Database('./techware_man_db.db', (err) => {
  if (err) {
    console.error('Error opening SQLite database:', err.message);
  } else {
    console.log('Connected to SQLite database');
  }
});

// - - - Init database - - - //
db.serialize(() => {
  console.log('Ensuring table exist...');
  db.run(`
    CREATE TABLE IF NOT EXISTS computer_components (
      product_id INTEGER PRIMARY KEY,
      product_name TEXT NOT NULL,
      manufacturer TEXT NOT NULL,
      category TEXT NOT NULL,
      price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      release_date TEXT NOT NULL
    )
  `);

  console.log('Table now exists.');
});

// for json parsing
app.use(bodyParser());


// - - - Web socket - - - //
app.ws.use((ctx, next) => {
  console.log('Client connected via WebSocket');

  clients.add(ctx.websocket);

  ctx.websocket.on('message', (message) => {
    console.log('Received message from client: ', message);
  });

  ctx.websocket.on('close', () => {
    console.log('Client disconnected');
    clients.delete(ctx.websocket);
  });

  return next();
});

// wrap db.all() in a Promise
function dbAll(query, params = []) {
  return new Promise((resolve, reject) => {
    db.all(query, params, (err, rows) => {
      if (err) {
        reject(err);
      } else {
        resolve(rows);
      }
    });
  });
}

// wrap db.run() in a Promise
function dbRun(query, params = []) {
  return new Promise((resolve, reject) => {
    db.run(query, params, function (err) {
      if (err) {
        reject(err);
      } else {
        resolve(this);  // resolve with the context of the query (lastID for inserts)
      }
    });
  });
}


// - - - Get all components - - - //
router.get('/api/computer-components', async (ctx) => {
  console.log('GET /api/computer-components');

  try {
    const rows = await dbAll('SELECT * FROM computer_components');
    console.log('Retrieved components:', rows);
	console.log('');
	
    ctx.body = rows;
  } catch (err) {
    console.error('Error retrieving components:', err.message);
    ctx.status = 500;
    ctx.body = { message: 'Error retrieving data from the database' };
  }
});


// - - - Get component by id- - - //
router.get('/api/computer-components/:id', async (ctx) => {
  console.log(`GET /api/computer-components/${ctx.params.id}`);
  const { id } = ctx.params;

  try {
	const result = await db.get('SELECT * FROM computer_components WHERE product_id = ?', id)
    console.log('Retrieved component:', result);
	console.log('');
	
    ctx.body = rows;
  } catch (err) {
    console.error('Error retrieving components:', err.message);
    ctx.status = 500;
    ctx.body = { message: 'Error retrieving data from the database' };
  }
});


// - - - Add new components - - - //
router.post('/api/computer-components', async (ctx) => {
  console.log('POST /api/computer-components');
  const { product_name, manufacturer, category, price, quantity, release_date } = ctx.request.body;
  console.log('New component data:', ctx.request.body);

  const query = `
    INSERT INTO computer_components (product_name, manufacturer, category, price, quantity, release_date)
    VALUES (?, ?, ?, ?, ?, ?)
  `;
  try {
    const result = await dbRun(query, [product_name, manufacturer, category, price, quantity, release_date]);
    console.log('Component added with product_id:', result.lastID);
	console.log('');

    clients.forEach((client) => {
      client.send(JSON.stringify({
        type: 'add',
        data: { 
          product_id: result.lastID,
          product_name,
          manufacturer,
          category,
          price,
          quantity,
          release_date
        }
      }));
    });

    ctx.body = { product_id: result.lastID };
  } catch (err) {
    console.error('Error adding component:', err.message);
    ctx.status = 500;
    ctx.body = { message: 'Error adding component' };
  }
});


// - - - Update component - - - //
router.put('/api/computer-components/:id', async (ctx) => {
  console.log(`PUT /api/computer-components/${ctx.params.id}`);
  const id = parseInt(ctx.params.id);
  const { product_name, manufacturer, category, price, quantity, release_date } = ctx.request.body;
  console.log('Update data:', ctx.request.body);
  
  const query = `
    UPDATE computer_components 
    SET product_name = ?, manufacturer = ?, category = ?, price = ?, quantity = ?, release_date = ?
    WHERE product_id = ?
  `;
  try {
    await dbRun(query, [product_name, manufacturer, category, price, quantity, release_date, id]);
    console.log('Component updated with product_id:', id);
	console.log('');
	
    clients.forEach((client) => {
      client.send(JSON.stringify({
        type: 'update',
        data: {
          product_id: id,
          product_name,
          manufacturer,
          category,
          price,
          quantity,
          release_date
        }
      }));
    });

    ctx.body = { product_id: id };
  } catch (err) {
    console.error('Error updating component:', err.message);
    ctx.status = 500;
    ctx.body = { message: 'Error updating component' };
  }
});

// - - - Delete component - - - //
router.delete('/api/computer-components/:id', async (ctx) => {
  console.log(`DELETE /api/computer-components/${ctx.params.id}`);
  const id = parseInt(ctx.params.id);
  
  const query = 'DELETE FROM computer_components WHERE product_id = ?';
  try {
    await dbRun(query, [id]);
    console.log('Component deleted with product_id:', id);
	console.log('');

    clients.forEach((client) => {
      client.send(JSON.stringify({
        type: 'delete',
        data: { product_id: id }
      }));
    });

    ctx.body = { product_id: id };
  } catch (err) {
    console.error('Error deleting component:', err.message);
    ctx.status = 500;
    ctx.body = { message: 'Error deleting component' };
  }
});


app.use(router.routes());
app.use(router.allowedMethods());

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
