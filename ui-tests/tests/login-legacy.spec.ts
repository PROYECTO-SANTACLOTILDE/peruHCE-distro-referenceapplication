// import { test, expect } from '@playwright/test';

// test('login en Legacy UI y llega al home', async ({ page }) => {
//   // Navega a la página de login
//   await page.goto('/login.htm');

//   // Completar usuario y contraseña
//   await page.fill('input[name="username"]', 'admin');
//   await page.fill('input[name="password"]', 'Admin123');

//   // Opcional: seleccionar local (depende de cómo esté tu login)
//   // Ejemplo: await page.selectOption('select#sessionLocation', { label: 'Outpatient Clinic' });

//   // Click en el botón de login
//   await page.click('input[type="submit"]');

//   // Esperar que la URL cambie a algo que indique que ya estamos dentro
//   await expect(page).toHaveURL(/.*openmrs.*/);

//   // Validar que aparece algún texto típico del home
//   await expect(page.locator('body')).toContainText('Home'); // Ajusta el texto si hace falta
// });

import { test, expect } from '@playwright/test';

test('login en Legacy UI y llega al home', async ({ page }) => {
  // Navega a la página de login (baseURL = http://localhost/openmrs)
  await page.goto('http://localhost/openmrs/login.htm', { waitUntil: 'networkidle' });

  // Completar usuario y contraseña usando los IDs correctos
  await page.fill('#username', 'admin');    // id="username"
  await page.fill('#password', 'Admin123'); // id="password"

  // Click en el botón de login (input submit con value "Iniciar sesión")
  await page.getByRole('button', { name: 'Log In' }).click();
  // Alternativa equivalente:
  // await page.click('button:has-text("Log In")');

  // Esperar que salgamos de la página de login
  await expect(page).not.toHaveURL(/\/login\.htm$/);

  // (Opcional) validar que estamos en alguna pantalla interna
  // Aquí puedes ajustar el texto según lo que veas en el home:
  // por ahora solo verificamos que hay algo de contenido típico
  await expect(page.locator('body')).toContainText('OpenMRS');
});
