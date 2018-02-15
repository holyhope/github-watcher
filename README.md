github-watcher
==============

Lets get a summarize of all github repository you want.

How to?
-------

 1. Generate github personal access: <https://github.com/blog/1509-personal-api-tokens>
    This application does not requires any specific access
 2. Get [OVH Functions client](https://docs.functions.ovh)
 3. Export credentials to your environment
    ```bash
    export USERNAME="my-github-login"
    export API_TOKEN="my-generated-token"
    ```
 4. Clone this repository
    ```bash
    git clone git@github.com:holyhope/github-watcher.git
    ```
 5. Deploy your function:
    ```bash
    cd where-you-cloned-the-repository
    ovh-functions deploy
    ```
 6. Execute the function with 1 parameter which is the github id: `owner/repository`:
    ```bash
    echo -n "holyhope/github-watcher" | ovh-functions exec github_watch
    ```

### Daily report

 1. Update `functions.yml` to execute the function daily
 2. Deploy once more the function
 3. Wait till the function is executed and check the logs
    ```bash
    ovh-functions logs github_watch
    ```

### Collect results

 1. Install a webserver which will receive 1 POST request for each result
    I recommend [ElasticSearch](https://www.elastic.co/fr/products/elasticsearch)
 2. Configure `POST_URL` in the `functions.yml` file
 3. Export your credentials:
    ```bash
    export POST_CREDENTIALS="user:my-password"
    ```
 4. Deploy the function one more time

/!\ Your webserver must be accessible over the Internet, so please use a basic authentication in the url
