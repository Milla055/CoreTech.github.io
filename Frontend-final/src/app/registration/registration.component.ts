import { Component, DestroyRef, EventEmitter, inject, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  AbstractControl,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { of } from 'rxjs';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { PhoneValidator } from '../phone-validator';

export function mustContainSpecialCharacters(control: AbstractControl) {
  const specialChars = [
    '?', '.', ':', '#', '/', '@', '&', ',', '!', '=', '-', '_', '%', '$'
  ];

  for (let i = 0; i < specialChars.length; i++) {
    if (control.value.includes(specialChars[i])) return null;
  }
  return { doesNotContainSpecialCharacters: true };
}

function emailIsUnique(control: AbstractControl) {
  if (control.value !== 'test@example.com') {
    return of(null);
  }

  return of({ emailIsNotUnique: true });
}

function usernameIsUnique(control: AbstractControl) {
  if (control.value !== 'username123') {
    return of(null);
  }

  return of({ usernameIsNotUnique: true });
}

function passwordIsMatching(control: AbstractControl) {
  if (control.value.password == control.value.confirmPassword) {
    return of(null);
  }
  return of({ passwordIsNotMatching: true });
}

@Component({
  selector: 'app-registration',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './registration.component.html',
  styleUrls: ['./registration.component.css'],
})

export class RegistrationComponent {
  @Output() cancel = new EventEmitter<void>();
  private destroyRef = inject(DestroyRef);
  
  // Jelszó megjelenítés állapotok
  showPassword: boolean = false;
  showConfirmPassword: boolean = false;
  
  // Success message állapot
  showSuccessMessage: boolean = false;
  
  form = new FormGroup({
    email: new FormControl('', {
      validators: [Validators.email, Validators.required],
      asyncValidators: [emailIsUnique],
    }),
    username: new FormControl('', {
      validators: [Validators.required],
      asyncValidators: [usernameIsUnique],
    }),
    password: new FormControl('', {
      validators: [Validators.required, Validators.minLength(8), mustContainSpecialCharacters],
    }),
    phone: new FormControl(' ', {
      validators: [Validators.required],
    }),
    confirmPassword: new FormControl('', {
      validators: [Validators.required],
      asyncValidators: [passwordIsMatching],
    }),
  });

  constructor(private AuthService: AuthService, private router: Router) {}

  passwordIsNotMatching: any;
  passwordIsMatching: any;

  get emailIsInvalid() {
    const c = this.form.controls.email;
    return c.touched && !c.pending && c.invalid;
  }

  get usernameIsInvalid() {
    const c = this.form.controls.username;
    return c.touched && !c.pending && c.invalid;
  }

  get confirmPasswordIsInvalid() {
    const pass = this.form.controls.password.value;
    const confirm = this.form.controls.confirmPassword.value;
    const touched =
      this.form.controls.confirmPassword.touched && this.form.controls.confirmPassword.dirty;
    return touched && pass && confirm && pass !== confirm;
  }

  get passwordIsInvalid() {
    return (
      this.form.controls.password.touched &&
      this.form.controls.password.dirty &&
      this.form.controls.password.invalid
    );
  }

  get phoneNumberIsInvalid() {
    return (
      this.form.controls.phone.touched &&
      this.form.controls.phone.dirty &&
      this.form.controls.phone.invalid
    );
  }

  // Jelszó megjelenítés/elrejtés váltása
  togglePasswordVisibility(field: 'password' | 'confirmPassword'): void {
    if (field === 'password') {
      this.showPassword = !this.showPassword;
    } else {
      this.showConfirmPassword = !this.showConfirmPassword;
    }
  }

  // Phone number input handler - auto-format as user types
  onPhoneInput(event: any): void {
    const input = event.target.value;
    const formatted = PhoneValidator.formatAsTyping(input);
    this.form.patchValue({ phone: formatted });
  }

  ngOnInit() {
    const savedForm = window.localStorage.getItem('saved-login-form');

    if (savedForm) {
      const loadedForm = JSON.parse(savedForm);
      this.form.patchValue({
        email: loadedForm.email,
      });
    }
  }

  closeLogin() {
    this.cancel.emit();
  }

  onSubmit() {
    if (this.form.invalid) return;

    // Validate phone number
    const phone = this.form.value.phone!;
    if (!PhoneValidator.isValid(phone)) {
      alert(PhoneValidator.getErrorMessage(phone));
      return;
    }

    const finalData = {
      email: this.form.value.email!,
      username: this.form.value.username!,
      password: this.form.value.password!,
      phone: phone,
    };

    this.AuthService.register(finalData).subscribe({
      next: (result) => {
        console.log(result);
        // Show success notification
        this.showSuccessMessage = true;
        
        // Auto-redirect after 2 seconds
        setTimeout(() => {
          this.showSuccessMessage = false;
          this.router.navigate(['/login']);
        }, 2000);
      },
      error: (err) => {
        console.error('Hiba történt:', err);
        alert('A regisztráció sikertelen.');
      },
    });
  }
}