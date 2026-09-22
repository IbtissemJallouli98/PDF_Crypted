# PDF de facture protégé

## Architecture

L’action `Facture__c.Protected_PDF_Generer` lance la génération depuis une facture. Le PDF est rendu par la page Visualforce `TB2SI_ProtectedInvoicePdf`, puis chiffré par `TB2SI_PdfEncryption` avec PDFBox AES-256. Salesforce ne stocke que le `ContentVersion` protégé, avec `FirstPublishLocationId` égal à la facture.

Le mot de passe d’ouverture et le mot de passe propriétaire sont distincts, aléatoires et conservés uniquement en mémoire pendant les appels. Aucun email n’est envoyé par cette implémentation et aucun mot de passe n’est écrit dans Salesforce, les logs ou le fichier.

## Configuration du service

Le service est dans `services/pdf-encryption`.

```powershell
cd services/pdf-encryption
Copy-Item .env.example .env
# Remplacer PDF_ENCRYPTION_API_TOKEN dans .env par un secret aléatoire
docker compose up --build
```

En dehors du développement local, publier le conteneur derrière un ingress HTTPS/TLS. Le endpoint `POST /v1/pdf/encrypt` exige `Authorization: Bearer <token>` et accepte :

```json
{
  "pdfBase64": "<PDF encodé en base64>",
  "userPassword": "<mot de passe d’ouverture>",
  "ownerPassword": "<mot de passe propriétaire distinct>"
}
```

La réponse 200 contient `pdfBase64`. Les erreurs sont génériques et le service ne journalise ni le corps, ni les mots de passe, ni le token. La taille maximale par défaut est 4 500 000 octets pour rester sous les limites d’appel Apex.

## Configuration Salesforce

1. Déployer les metadata Salesforce et le service.
2. Dans la Named Credential `TB2SI_PdfEncryption`, remplacer `https://pdf-encryption.example.invalid` par l’URL HTTPS publique du service.
3. Dans l’External Credential `TB2SI_PdfEncryption_EC`, renseigner la valeur secrète du principal `PDF Encryption Principal` dans Setup. Ne pas la committer dans le dépôt.
4. Attribuer le Permission Set `TB2SI_ProtectedInvoicePdf` aux utilisateurs autorisés.
5. Vérifier que le Permission Set autorise l’accès au principal d’External Credential et que l’URL répond à `/healthz`.

Le placeholder `.invalid` est volontaire : tant qu’il n’est pas remplacé et que le principal n’est pas renseigné, le traitement passe en `Failed` et aucun PDF non protégé n’est conservé ou envoyé.

## Statuts et sécurité

Les champs ajoutés à `Facture__c` sont `Protected_PDF_Status__c`, `Protected_PDF_Error__c`, `Protected_PDF_File_Id__c` et `Protected_PDF_Generated_At__c`. Le mot de passe n’est pas un champ.

Une facture déjà en `Processing` ou `Succeeded` est idempotente : une relance ne crée pas de second fichier. Une erreur du service bloque la réussite et aucune transmission n’est effectuée. La remise séparée du mot de passe reste à brancher sur un fournisseur SMS ou un portail authentifié ; jusque-là, l’automatisation d’envoi doit rester désactivée.

## Vérifications exécutées

- Déploiement metadata validé puis effectué dans la sandbox `WEBSITE`.
- `TB2SI_ProtectedInvoicePdfTest` exécuté dans la sandbox : 5 méthodes et le `@TestSetup` sont passés.
- Le test Apex vérifie le rendu depuis la facture, les lignes, le rattachement Files, le refus d’un identifiant inexistant, l’échec du callout, l’absence de fichier en erreur et l’idempotence.
- Le test Java/PDFBox est fourni dans `services/pdf-encryption/src/test`; il vérifie l’ouverture avec le bon mot de passe, le refus avec un mauvais mot de passe et l’impression. Il n’a pas pu être exécuté dans cet environnement car Maven et Docker ne sont pas installés.
