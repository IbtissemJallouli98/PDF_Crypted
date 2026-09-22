import { LightningElement, api } from 'lwc';
import startGeneration from '@salesforce/apex/TB2SI_ProtectedInvoicePdfController.startGeneration';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Tb2siProtectedInvoicePdfAction extends LightningElement {
    @api recordId;
    isRunning = false;

    async handleGenerate() {
        this.isRunning = true;
        try {
            const result = await startGeneration({ factureId: this.recordId });
            const variant = result.status === 'Processing' ? 'success' : 'info';
            this.dispatchEvent(new ShowToastEvent({
                title: 'PDF protégé',
                message: result.message,
                variant
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            const message = error?.body?.message || 'La génération n’a pas pu être planifiée.';
            this.dispatchEvent(new ShowToastEvent({ title: 'PDF protégé', message, variant: 'error' }));
        } finally {
            this.isRunning = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
