/**
 * @fileoverview Search developers.google.com/web for articles tagged
 * "Headless Chrome" and scrape results from the results page.
 */

const browser = await puppeteer.launch();
const page = await browser.newPage();

await page.goto("https://www.wisebooks.io/all_people.html");

const allPostsSelector = "#allposts > div > div > div > div > a";
await page.waitForSelector(allPostsSelector);

const allReadMores = await page.evaluate(allPostsSelector => {
    const anchors = Array.from(document.querySelectorAll(allPostsSelector));
    return anchors.map(anchor => {
        const title = anchor.textContent.split("|")[0].trim();
        return `${anchor.href}`;
    });
}, allPostsSelector);

for (let readMore of allReadMores) {
    await page.click(readMore);

    const booksSelector = "#books > div > div > div> div.bookbuttons > a";
    await page.waitForSelector(booksSelector);

    // Extract the results from the page.
    const links = await page.evaluate(booksSelector => {
        const anchors = Array.from(document.querySelectorAll(booksSelector));
        return anchors.map(anchor => {
            const title = anchor.textContent.split("|")[0].trim();
            return `${anchor.href}`;
        });
    }, booksSelector);
    // console.log(links.join('\n'));

    const productTitleSelector = "#productTitle";

    var titles = [];

    for (let link of links) {
        // console.log(link);
        await page.goto(link);
        await page.waitForSelector(productTitleSelector);
        let email = await page.evaluate(sel => {
            let element = document.querySelector(sel);
            return element ? element.innerHTML : null;
        }, productTitleSelector);
        console.log(email);
    }
}

await browser.close();
