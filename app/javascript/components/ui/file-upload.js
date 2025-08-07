import React, { useState, useRef } from 'react';
import { cn } from '../../lib/utils';
import { Button } from './button';
import { Progress } from './progress';

const FileUpload = React.forwardRef(({
  className,
  accept,
  multiple = false,
  maxSize = 10, // in MB
  onUpload,
  onError,
  uploadUrl,
  csrfToken,
  ...props
}, ref) => {
  const [files, setFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState(null);
  const fileInputRef = useRef(null);

  const handleFileChange = (e) => {
    const selectedFiles = Array.from(e.target.files);
    
    // Validate file size
    const invalidFiles = selectedFiles.filter(file => file.size > maxSize * 1024 * 1024);
    if (invalidFiles.length > 0) {
      const errorMessage = `File${invalidFiles.length > 1 ? 's' : ''} too large. Maximum size is ${maxSize}MB.`;
      setError(errorMessage);
      if (onError) onError(errorMessage);
      return;
    }
    
    setError(null);
    setFiles(multiple ? [...files, ...selectedFiles] : selectedFiles);
  };

  const handleUpload = async () => {
    if (files.length === 0) return;
    
    setUploading(true);
    setProgress(0);
    setError(null);
    
    try {
      const formData = new FormData();
      
      files.forEach((file, index) => {
        formData.append(multiple ? `files[${index}]` : 'file', file);
      });
      
      const xhr = new XMLHttpRequest();
      
      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          const percentComplete = Math.round((event.loaded / event.total) * 100);
          setProgress(percentComplete);
        }
      });
      
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          const response = JSON.parse(xhr.responseText);
          setUploading(false);
          setFiles([]);
          if (onUpload) onUpload(response);
        } else {
          throw new Error(`Upload failed with status ${xhr.status}`);
        }
      });
      
      xhr.addEventListener('error', () => {
        setUploading(false);
        const errorMessage = 'Upload failed. Please try again.';
        setError(errorMessage);
        if (onError) onError(errorMessage);
      });
      
      xhr.open('POST', uploadUrl);
      xhr.setRequestHeader('X-CSRF-Token', csrfToken);
      xhr.send(formData);
    } catch (err) {
      setUploading(false);
      setError(err.message);
      if (onError) onError(err.message);
    }
  };

  const handleRemoveFile = (index) => {
    const newFiles = [...files];
    newFiles.splice(index, 1);
    setFiles(newFiles);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    const droppedFiles = Array.from(e.dataTransfer.files);
    
    // Validate file size
    const invalidFiles = droppedFiles.filter(file => file.size > maxSize * 1024 * 1024);
    if (invalidFiles.length > 0) {
      const errorMessage = `File${invalidFiles.length > 1 ? 's' : ''} too large. Maximum size is ${maxSize}MB.`;
      setError(errorMessage);
      if (onError) onError(errorMessage);
      return;
    }
    
    setError(null);
    setFiles(multiple ? [...files, ...droppedFiles] : droppedFiles);
  };

  const triggerFileInput = () => {
    fileInputRef.current.click();
  };

  return (
    <div
      className={cn('space-y-4', className)}
      {...props}
      ref={ref}
    >
      <div
        className={cn(
          'border-2 border-dashed rounded-lg p-6 text-center cursor-pointer',
          'hover:border-primary transition-colors',
          'focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
          error && 'border-destructive'
        )}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
        onClick={triggerFileInput}
        tabIndex={0}
        role="button"
        aria-label="Upload file"
      >
        <input
          type="file"
          ref={fileInputRef}
          className="hidden"
          accept={accept}
          multiple={multiple}
          onChange={handleFileChange}
        />
        <div className="flex flex-col items-center justify-center space-y-2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-10 w-10 text-muted-foreground"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
            />
          </svg>
          <div className="text-sm text-muted-foreground">
            <span className="font-medium">Click to upload</span> or drag and drop
          </div>
          <div className="text-xs text-muted-foreground">
            {accept ? `Accepted file types: ${accept}` : 'All file types accepted'}
          </div>
          <div className="text-xs text-muted-foreground">
            Maximum file size: {maxSize}MB
          </div>
        </div>
      </div>

      {error && (
        <div className="text-sm text-destructive">
          {error}
        </div>
      )}

      {files.length > 0 && (
        <div className="space-y-2">
          <div className="text-sm font-medium">Selected files:</div>
          <ul className="space-y-2">
            {files.map((file, index) => (
              <li
                key={`${file.name}-${index}`}
                className="flex items-center justify-between text-sm p-2 border rounded-md"
              >
                <div className="flex items-center space-x-2">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-4 w-4 text-muted-foreground"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  <span>{file.name}</span>
                </div>
                <button
                  type="button"
                  className="text-destructive hover:text-destructive/90"
                  onClick={() => handleRemoveFile(index)}
                  disabled={uploading}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-4 w-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      {uploading && (
        <div className="space-y-2">
          <div className="text-sm font-medium">Uploading...</div>
          <Progress value={progress} />
        </div>
      )}

      {files.length > 0 && !uploading && (
        <div className="flex justify-end">
          <Button onClick={handleUpload}>
            Upload {files.length} file{files.length !== 1 ? 's' : ''}
          </Button>
        </div>
      )}
    </div>
  );
});

FileUpload.displayName = 'FileUpload';

export { FileUpload };