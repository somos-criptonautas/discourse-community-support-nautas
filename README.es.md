# Community Support

[![Discourse Theme](https://github.com/somos-criptonautas/discourse-community-support-nautas/actions/workflows/discourse-theme.yml/badge.svg)](https://github.com/somos-criptonautas/discourse-community-support-nautas/actions/workflows/discourse-theme.yml)

[ENGLISH](README.md) | **ESPAÑOL**

Componente de tema de Discourse, independiente de la pasarela de pago, para apoyo a la comunidad, donaciones y widgets de recaudación. El mismo sistema de presentación se reutiliza en modales, publicaciones, plugin outlets y ubicaciones HTML como Discourse Ads.

Normalmente las donaciones son enlaces salientes. Con [discourse-btcpay-subscriptions](https://github.com/somos-criptonautas/discourse-btcpay-subscriptions) instalado, un método puede cobrar dentro de Discourse — ver [Donaciones con BTCPay](#donaciones-con-btcpay). Todas las funciones de BTCPay vuelven al comportamiento anterior cuando el plugin no está, así que el componente funciona igual sin él.

## Requisitos

- Discourse 3.4+ — el componente usa componentes Glimmer `.gjs` y el esquema de objetos para los ajustes
- Opcional: [discourse-btcpay-subscriptions](https://github.com/somos-criptonautas/discourse-btcpay-subscriptions) para donaciones dentro del sitio y totales en vivo

## Instalación

Admin → Personalizar → Temas → Componentes → Instalar → Desde un repositorio git, y añade la URL del repositorio. Si el repositorio es privado, usa la URL SSH y añade la clave de despliegue que muestra Discourse a las *Deploy keys* del repositorio.

Instálalo como componente y añádelo a los temas que deban mostrarlo.

## Funciones

- Activador manual `#donate` — cualquier enlace con ese href abre el modal
- Control de visibilidad por miembros/anónimos, nivel de confianza, rutas y grupos excluidos
- Los grupos excluidos ocultan los widgets de outlet y los embeds genéricos, mientras que los bloques contextuales `[wrap=donate]` y el enlace `#donate` siguen disponibles
- Métodos de donación con logotipos, enlaces y valores copiables (IBAN, alias, dirección…)
- El campo de importe y el botón del método destacado van dentro de la propia caja de apoyo
- Donaciones BTCPay dentro del sitio, con un campo de importe en lugar del enlace saliente
- Traducciones por método usando la lista de idiomas de Discourse
- Destacados configurables en la cabecera, con traducción por elemento desde la misma lista
- Objetivo y barra de progreso, alimentados por un ajuste manual o por los totales en vivo de BTCPay
- Periodos de objetivo único, mensual y anual
- Avatares de colaboradores, desde una lista manual, desde grupos y desde donantes reales de BTCPay
- Diseños Classic, Minimal y Modern
- Vistas Full, Compact, Minimal, Progress y Sidebar
- Envoltorios en publicaciones con `[wrap=donate*]`
- Embed HTML genérico para Discourse Ads y otras ubicaciones que admitan HTML
- Renderizado configurable en plugin outlets mediante `renderInOutlet`
- Diseño adaptable y soporte de movimiento reducido
- Semántica de progreso accesible y controles de copia accesibles por teclado

## Métodos de donación

Los métodos se configuran en el ajuste de objetos `donation_methods`. Un método puede marcarse como `featured`, lo que lo promueve a su propia sección sobre la cuadrícula.

```yaml
donation_methods:
  - featured: true
    name: "PayPal"
    description: "Apoya a la comunidad con PayPal."
    button_text: "Apoyar con PayPal"
    url: "https://paypal.me/ejemplo"
  - name: "Transferencia"
    description: "Transferencia directa, sin comisiones."
    button_text: "Ver datos"
    copy_label: "IBAN"
    copy_value: "ES00 0000 0000 0000 0000 0000"
```

| Campo | Para qué sirve |
| --- | --- |
| `featured` | Usa este método para el campo de importe y el botón de la caja |
| `name`, `description`, `button_text` | Texto de la tarjeta (obligatorio) |
| `url` | URL de apoyo saliente. Se ignora cuando `use_btcpay` está activo |
| `use_btcpay` | Cobra la donación en el sitio mediante el plugin de BTCPay |
| `icon` | Logotipo del proveedor, opcional (subida) |
| `owner`, `provider` | Beneficiario y proveedor de pago opcionales, mostrados en la tarjeta |
| `copy_label`, `copy_value` | Valor copiable de un clic, como un IBAN o una dirección |
| `translations` | Traducción por idioma de los campos de texto |

## Donaciones con BTCPay

Activa `use_btcpay` en un método para cobrar la donación sin salir de Discourse:

```yaml
donation_methods:
  - name: "Bitcoin"
    description: "Dona con Bitcoin o Lightning."
    button_text: "Donar"
    use_btcpay: true
```

La tarjeta muestra entonces un campo de importe y un botón en lugar de un enlace. Al pulsar el botón:

1. se envía el importe a `POST /btcpay/donate.json`, y el plugin responde con un id de factura, una URL de modal y una URL de checkout alojado;
2. se carga el propio script modal de BTCPay y se llama a `window.btcpay.showInvoice()` con ese id de factura;
3. si el script no carga, se redirige a la página de checkout alojada.

El botón queda deshabilitado mientras se crea la factura y mientras la ventana está abierta, de modo que un doble clic no puede apilar dos ventanas. Los visitantes anónimos ven un botón de inicio de sesión, porque el endpoint solo atiende a usuarios identificados. Los errores de validación del plugin — un importe por debajo del mínimo, el límite de peticiones — se muestran bajo el campo.

El tema nunca habla directamente con BTCPay ni guarda ninguna clave de API. El id de pedido que atribuye una donación a un usuario de Discourse se genera en el servidor, así que el navegador no puede influir en él.

El mismo plugin alimenta dos piezas de solo lectura desde `GET /btcpay/donations.json`:

- el **total de la barra de apoyo**, que sustituye al ajuste manual `support_current` (`support_goal` sigue siendo manual);
- los **avatares de colaboradores**, combinados con la lista configurada a mano.

Ambas vuelven a sus ajustes manuales si la petición falla o el plugin no está. El endpoint se pide una sola vez por render de página y lo comparten todas las tarjetas, la barra y la lista de avatares.

El importe mínimo, la moneda de la donación y el límite de peticiones son ajustes del plugin, no de este componente.

## Disposición

La disposición por defecto es una caja, después la barra de progreso y después el resto de métodos:

```
┌─ caja de apoyo ────────────────────────────┐
│ ♥  Sostener nuestra comunidad              │
│    Los proyectos financiados…   [ 10.00  ] │
│    [sin anuncios] [comunidad]   [  Donar ] │
└────────────────────────────────────────────┘
  120 EUR de 200 EUR · Mensual          60%
  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░
┌ PayPal ──────────┐ ┌ Transferencia ──────┐
```

La caja es la cabecera y el método destacado en una sola pieza: el texto a la izquierda y el campo de importe y el botón de ese método a la derecha. Los demás métodos siguen en la cuadrícula. El icono lo define `support_icon` y es el único icono de la disposición.

## Barra de apoyo

La barra de apoyo se activa globalmente y puede mostrarse de forma independiente en el modal, los embeds en publicaciones, los plugin outlets y los embeds genéricos. Admite disposición inline, apilada y compacta.

Las cifras se leen en una sola línea —total recaudado, contra qué se mide, el periodo y el porcentaje— para que nada quede separado a lo ancho de la barra. `support_label` se usa como nombre accesible de la barra, no como título visible.

Por debajo del primer objetivo usa `tertiary-low` como pista y `tertiary` como relleno; al 100% exacto — y en cada hito exacto de 200%, 300%… — pista y relleno usan `success`. Entre hitos la pista usa `success-low` y el ciclo actual usa `success` como relleno, mientras el porcentaje mostrado sigue indicando el total real (por ejemplo 125% o 220%).

## Avatares de colaboradores

La barra de apoyo puede mostrar un número configurable de avatares pequeños. Los colaboradores vienen de tres fuentes, combinadas en este orden, y en caso de nombre repetido gana la primera:

1. el ajuste manual `supporters` — un nombre de usuario de Discourse, más un importe opcional, con perfil y avatar resueltos en tiempo de ejecución;
2. los donantes reales que informa el plugin de BTCPay, si está instalado;
3. los miembros de los grupos indicados en `supporter_groups`, del más reciente al más antiguo.

Cuando hay más colaboradores que avatares visibles, un menú `+N` abre la lista completa. `show_supporter_amounts` añade los importes a esa lista.

## Embeds en publicaciones

Activa `enable_post_embed` y usa cualquiera de estos envoltorios en una publicación:

```markdown
[wrap=donate]
[/wrap]

[wrap=donate-compact]
[/wrap]

[wrap=donate-minimal]
[/wrap]

[wrap=donate-progress]
[/wrap]
```

El envoltorio elige la vista, mientras que el ajuste global `design` controla el diseño visual.

## Embed genérico

Usa el marcador de embed estable allí donde el componente pueda decorar HTML cocinado:

```html
<div data-donation-widget="support"></div>
```

El marcador puede sobrescribir la presentación global:

```html
<div
  data-donation-widget="support"
  data-view="compact"
  data-design="minimal"
></div>
```

El HTML se mantiene estable mientras el componente es dueño de todo el marcado y el CSS, lo que hace el embed adecuado para ubicaciones HTML de Discourse Ads. Crea un anuncio HTML con el marcador y colócalo en el outlet de Ads que quieras; el anuncio no necesita CSS propio de donaciones.

## Plugin outlets

Activa `outlet_enabled` e indica uno o más nombres de outlet en `outlet_locations`, separados por `|`. El componente renderiza mediante `api.renderInOutlet()`.

Los widgets de outlet y los embeds genéricos respetan `url_must_contain`, `display_on_homepage`, `show_for_members`, `show_for_anon`, `trust_level` y `excluded_groups`, y se vuelven a comprobar en cada navegación. Los embeds en publicaciones se saltan esas comprobaciones a propósito: un bloque `[wrap=donate]` lo colocó ahí quien escribió la publicación.

Ejemplos: `above-main-container`, `before-topic-list`, `after-topic-list`, `topic-list-bottom`, `below-site-header`, `main-outlet-bottom`, `before-main-outlet`. La disponibilidad exacta depende de la versión de Discourse y de los temas y componentes instalados.

La vista y el diseño del outlet se configuran de forma independiente de los valores globales.

## Vistas y diseños

El diseño controla el lenguaje visual:

- `classic` — tarjetas equilibradas, estilo comunidad
- `minimal` — presentación compacta y sobria
- `modern` — tipografía mayor, más jerarquía, tarjetas elevadas

La vista controla cuánto contenido se muestra:

- `full` — cabecera completa, método destacado y lista de métodos
- `compact` — menos adorno para ubicaciones estrechas
- `minimal` — presentación centrada en los métodos
- `progress` — solo objetivo y progreso
- `sidebar` — un bloque compacto hecho a propósito para outlets de la barra lateral: icono, título corto, barra fina, campo de importe y botón. No es la caja completa reducida: prescinde del texto de cabecera y de la cuadrícula de métodos porque no caben.

Diseño y vista son ortogonales a propósito: cualquier vista funciona con cualquier diseño.

## Iconos

`support_icon` define el único icono de la disposición: la caja, el bloque de la barra lateral y el icono de reserva cuando un método no tiene logotipo subido. Por defecto es `ph-dt-hand-heart`, que requiere el [componente de iconos Phosphor Duotone](https://github.com/somos-criptonautas/discourse-phosphor-duotone-icons-nautas) instalado; usa `heart` o cualquier otro icono del núcleo si no usas ese componente.

## Idiomas

El componente incluye inglés y español; el resto de idiomas recurre al inglés. Los nombres de los métodos, las descripciones, las etiquetas de botón y los destacados de la cabecera se traducen por elemento en sus propios ajustes, no en los archivos de idioma, para que los administradores traduzcan sus textos sin tocar código.

## Desarrollo

```bash
pnpm install
pnpm lint          # eslint, prettier, stylelint, ember-template-lint
pnpm lint:fix
```

Las pruebas están en `test/acceptance/` y se ejecutan contra una instancia real de Discourse en CI. Cada push a `main` o pull request lanza el workflow compartido de temas de [discourse/.github](https://github.com/discourse/.github), que pasa los linters, valida `locales/en.yml` y `.discourse-compatibility`, y ejecuta la suite de QUnit.

Para ejecutarlas en local hace falta un checkout de desarrollo de Discourse:

```bash
cd ruta/a/discourse
bin/rake "themes:install[/ruta/a/discourse-community-support-nautas]"
bin/rake "themes:qunit[name,Community Support]"
```

## Licencia

GPL-3.0. Consulta [LICENSE](LICENSE).

Texto de este README bajo [CC BY-NC-SA 4.0](CC-BY-NC-SA-4.0.txt).
