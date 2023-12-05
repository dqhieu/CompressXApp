//
//  FileDownloader.swift
//  Onboarding
//
//  Created by Dinh Quang Hieu on 6/8/24.
//

import Foundation

class FileDownloader: NSObject, URLSessionDownloadDelegate {
  private var progressCallback: ((Double) -> Void)?
  private var completionCallback: ((Result<URL, Error>) -> Void)?
  private var destinationURL: URL
  private var downloadTask: URLSessionDownloadTask?

  init(destinationURL: URL) {
    self.destinationURL = destinationURL
  }

  func downloadFile(from urlString: String, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
    guard let url = URL(string: urlString) else {
      completion(.failure(URLError(.badURL)))
      return
    }

    self.progressCallback = progress
    self.completionCallback = completion

    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    downloadTask = session.downloadTask(with: url)
    downloadTask?.resume()
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    progressCallback?(progress)
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    do {
      // Move downloaded file from temporary location to desired location
      try FileManager.default.moveItem(at: location, to: destinationURL)
      completionCallback?(.success(destinationURL))
    } catch {
      completionCallback?(.failure(error))
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      completionCallback?(.failure(error))
    }
  }

  func cancel() {
    downloadTask?.cancel()
    downloadTask = nil
  }
}
