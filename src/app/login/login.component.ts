import { Component, DestroyRef, EventEmitter, inject, OnInit, Output } from '@angular/core';
import {
  AbstractControl,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { debounceTime, of } from 'rxjs';

/*export function mustContainSpecialCharacters(control: AbstractControl) {
  const specialChars = ['?', '.', ':', '#', '/', '@', '&', ',', '!', '=', '-', '_', '%', '$'];

  for (let i = 0; i < specialChars.length; i++) {
    if (control.value.includes(specialChars[i])) return null;
  }
  return { doesNotContainSpecialCharacters: true };
}*/

/*function emailIsUnique(control: AbstractControl) {
  if (control.value === 'test@example.com') {
    return of(null);
  }

  return of({ emailIsNotUnique: true });
}*/

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
})
export class LoginComponent implements OnInit {
  @Output() cancel = new EventEmitter<void>();
  private destroyRef = inject(DestroyRef);
  form = new FormGroup({
    email: new FormControl('', {
      validators: [Validators.email, Validators.required],
      /*asyncValidators: [emailIsUnique],*/
    }),
    password: new FormControl('', {
      validators: [Validators.required, /*mustContainQuestionMark*/],
    }),
  });

  get emailIsInvalid() {
    return (
      this.form.controls.email.touched &&
      this.form.controls.email.dirty &&
      this.form.controls.email.invalid
    );
  }

  get passwordIsInvalid() {
    return (
      this.form.controls.password.touched &&
      this.form.controls.password.dirty &&
      this.form.controls.password.invalid
    );
  }

  ngOnInit() {
    const savedForm = window.localStorage.getItem('saved-login-form');

    if(savedForm) {
      const loadedForm = JSON.parse(savedForm);
      this.form.patchValue({
        email: loadedForm.email
      })
    }

    const subscription = this.form.valueChanges.pipe(debounceTime(500)).subscribe({
      next: (value) => {
        window.localStorage.setItem('saved-login-form', JSON.stringify({ email: value.email }));
      },
    });

    this.destroyRef.onDestroy(() => subscription.unsubscribe());
  }

  closeLogin() {
    this.cancel.emit();
  }

  onSubmit() {
    const enteredEmail = this.form.value.email;
    const enteredPassword = this.form.value.password;

    console.log(enteredEmail, enteredPassword);
  }
}
