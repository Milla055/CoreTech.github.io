import { Component, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NewsletterService } from '../services/newsletter.service';

@Component({
  selector: 'app-newsletter',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './newsletter.component.html',
  styleUrls: ['./newsletter.component.css']
})
export class NewsletterComponent {
  email: string = '';
  isLoading: boolean = false;
  notification: { message: string; type: 'success' | 'error' } | null = null;

  constructor(@Inject(NewsletterService) private newsletterService: NewsletterService) {}

  subscribe(): void {
    if (!this.email || !this.email.trim()) {
      this.showNotification('Kérjük, add meg az email címed!', 'error');
      return;
    }

    if (!this.isValidEmail(this.email)) {
      this.showNotification('Kérjük, adj meg egy érvényes email címet!', 'error');
      return;
    }

    this.isLoading = true;

    this.newsletterService.subscribe(this.email.trim()).subscribe({
      next: (response) => {
        this.isLoading = false;
        
        if (response.status === 'Subscribed') {
          this.showNotification('Sikeresen feliratkoztál a hírlevélre!', 'success');
          this.email = '';
        } else if (response.status === 'AlreadySubscribed') {
          this.showNotification('Már feliratkoztál a hírlevélre!', 'error');
        } else if (response.status === 'UserNotFound') {
          this.showNotification('Ezzel az email címmel nincs regisztrált felhasználó.', 'error');
        } else {
          this.showNotification(response.message || 'Hiba történt.', 'error');
        }
      },
      error: (error) => {
        this.isLoading = false;
        
        if (error.status === 404) {
          this.showNotification('Ezzel az email címmel nincs regisztrált felhasználó.', 'error');
        } else if (error.status === 400) {
          this.showNotification('Már feliratkoztál a hírlevélre!', 'error');
        } else {
          this.showNotification('Hiba történt a feliratkozás során.', 'error');
        }
      }
    });
  }

  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  private showNotification(message: string, type: 'success' | 'error'): void {
    this.notification = { message, type };
    setTimeout(() => {
      this.notification = null;
    }, 4000);
  }
}